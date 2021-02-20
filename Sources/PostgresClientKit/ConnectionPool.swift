//
//  ConnectionPool.swift
//  PostgresClientKit
//
//  Copyright 2019 David Pitfield and the PostgresClientKit contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A pool of re-usable, interchangeable `Connection` instances.
///
/// Using a `ConnectionPool` allows an application to acquire an existing `Connection` from the
/// pool, use that connection to perform one or more SQL statements, and then release it for use
/// elsewhere in the application.
///
/// The `ConnectionPoolConfiguration` used to create a `ConnectionPool` specifies the number of
/// connections in the pool, how long a request for a connection will wait for a connection to
/// become available, and other characteristics of the pool.
///
/// All connections in a `ConnectionPool` are created from the same `ConnectionConfiguration`.
/// They also have the same `ConnectionDelegate` (if a delegate is specified).  Consequently
/// any connection in a pool is interchangeable with any other.
///
/// Use `ConnectionPool.acquireConnection(completionHandler:)` to request a connection from a
/// `ConnectionPool`.  This method is non-blocking: its completion handler is asynchronously
/// executed when a connection is successfully allocated to the request or if an error occurs.
/// To release the connection back to the pool, call `ConnectionPool.releaseConnection(_:)`.
///
/// Alternately, use `ConnectionPool.withConnection(completionHandler:)` to acquire a connection
/// that is automatically released after execution of the completion handler.
///
/// When a connection is released to a `ConnectionPool`, there should be no transaction underway.
/// Pair each SQL `BEGIN` command with either a `COMMIT` or `ROLLBACK` command (or equivalently,
/// use the `Connection.beginTransaction()`, `Connection.commitTransaction()`, and
/// `Connection.rollbackTransaction()` methods).
///
/// In general, do not close a `Connection` acquired from a `ConnectionPool`.  If a connection is
/// closed (whether explicitly or because of an unrecoverable error) then, when that connection is
/// released, it will be discarded from the pool, allowing a new connection to be created and added
/// to the pool.
///
/// The `ConnectionPool` class is threadsafe: multiple threads may concurrently operate against a
/// `ConnectionPool` instance.  Connections acquired from the pool are subject to the threadsafety
/// constraints described by the API documentation for `Connection`.
public class ConnectionPool {
    
    //
    // Public API
    //
    // The public API is threadsafe.
    //
    
    /// Creates a `ConnectionPool`.
    ///
    /// - Parameters:
    ///   - connectionPoolConfiguration: the configuration for the `ConnectionPool`
    ///   - connectionConfiguration: the configuration for `Connection` instances in the pool
    ///   - connectionDelegate: an optional delegate for the `Connection` instances
    public init(connectionPoolConfiguration: ConnectionPoolConfiguration,
                connectionConfiguration: ConnectionConfiguration,
                connectionDelegate: ConnectionDelegate? = nil) {
        
        _connectionPoolConfiguration = connectionPoolConfiguration
        self.connectionConfiguration = connectionConfiguration
        self.connectionDelegate = connectionDelegate
        
        computeMetrics(reset: true) // initialize the metrics
        scheduleMetricsLogging()    // schedule periodic logging of the metrics
    }
    
    /// The configuration of this `ConnectionPool`.
    ///
    /// The `ConnectionPoolConfiguration` is mutable.  Configuration changes take effect for
    /// subsequent requests for connections.
    public var connectionPoolConfiguration: ConnectionPoolConfiguration {
        get {
            return threadsafe { _connectionPoolConfiguration }
        }
        
        set {
            threadsafe {
                _connectionPoolConfiguration = newValue
                connectionPoolConfigurationChangeCount += 1
            }
            
            scheduleMetricsLogging()
        }
    }
    
    /// The configuration of `Connection` instances in this `ConnectionPool`.
    public let connectionConfiguration: ConnectionConfiguration
    
    /// An optional delegate for `Connection` instances in this `ConnectionPool`.
    public let connectionDelegate: ConnectionDelegate?
    
    /// Requests a `Connection` from this `ConnectionPool`.
    ///
    /// This method is non-blocking: its completion handler is asynchronously executed when a
    /// connection is successfully allocated or an error occurs.
    /// `ConnectionPoolConfiguration.dispatchQueue` controls the `DispatchQueue` on which the
    /// completion handler is executed.
    ///
    /// If the request backlog is too large (`ConnectionPoolConfiguration.maximumPendingRequests`),
    /// the request will fail with `PostgresError.tooManyRequestsForConnections`.
    ///
    /// If a connection is available, it will be allocated to the request and passed to the
    /// completion handler.  Otherwise, the request will join the backlog of pending requests.
    /// As connections become available, they are allocated to the pending requests in the order
    /// those requests were received.
    ///
    /// If a connection is not allocated to the request before it times out
    /// (`ConnectionPoolConfiguration.pendingRequestTimeout`), the request will fail with
    /// `PostgresError.timedOutAcquiringConnection`.
    ///
    /// When a connection is successfully allocated to the request, the completion handler
    /// (or any code it triggers) can use that connection to perform one or more SQL statements.
    /// When finished with the connection, call `releaseConnection(_:)` to release it back to
    /// this `ConnectionPool`.  If `releaseConnection(_:)` is not called before the allocated
    /// connection times out (`ConnectionPoolConfiguration.allocatedConnectionTimeout`), the
    /// connection will be forcibly closed and removed from the `ConnectionPool`.
    ///
    /// Example:
    ///
    ///     connectionPool.acquireConnection { result in
    ///         do {
    ///             let connection = try result.get()
    ///             defer { connectionPool.releaseConnection(connection) }
    ///
    ///             let statement = try connection.prepareStatement(text: ...)
    ///             ...
    ///         } catch {
    ///             ...
    ///         }
    ///     }
    ///
    /// - Parameter completionHandler: a completion handler, passed a value that either indicates
    ///     success (with an associated `Connection`) or failure (with an associated `Error`)
    public func acquireConnection(
        completionHandler: @escaping (Result<Connection, Error>) -> Void) {
        
        threadsafe {
            let request = Request(connectionPool: self, completionHandler: completionHandler)
            
            // Verify the connection pool hasn't been closed.
            guard !_isClosed else {
                request.failure(PostgresError.connectionPoolClosed)
                return
            }
            
            // Enforce the maximum number of pending requests, if set.
            if let maximumPendingRequests = _connectionPoolConfiguration.maximumPendingRequests {
                guard pendingRequests.count < maximumPendingRequests else {
                    unsuccessfulRequestsTooBusy += 1
                    request.failure(PostgresError.tooManyRequestsForConnections)
                    return
                }
            }
            
            // Add this request to the queue.
            pendingRequests.append(request)
            
            // Update the metrics accumulators.
            self.maximumPendingRequests =
                max(self.maximumPendingRequests, self.pendingRequests.count)
            
            // Schedule a timeout for fulfilling it.
            scheduleTimeoutOfPendingRequest(request)
            
            // And see if we can fulfill any requests.
            allocateConnections()
        }
    }
    
    /// Releases a `Connection` back to this `ConnectionPool`.
    ///
    /// Each `Connection` acquired by calling `acquireConnection(completionHandler:)` should be
    /// released exactly once.  After invoking this method, do not further operate on the
    /// `Connection` instance.
    ///
    /// - Parameter connection: the `Connection` to release
    public func releaseConnection(_ connection: Connection) {
        threadsafe {
            releaseConnection(connection, timedOut: false)
        }
    }
    
    /// Requests a `Connection` from this `ConnectionPool`, automatically releasing it after
    /// executing the specified completion handler.
    ///
    /// This method operates identically to `acquireConnection(completionHandler:)`, except that
    /// the acquired connection is automatically released after executing the completion handler.
    ///
    /// Do not call `releaseConnection(_:)` on the `Connection` passed to the completion handler.
    ///
    /// Example:
    ///
    ///     connectionPool.withConnection { result in
    ///         do {
    ///             let connection = try result.get()
    ///             let statement = try connection.prepareStatement(text: ...)
    ///             ...
    ///         } catch {
    ///             ...
    ///         }
    ///     }
    ///
    /// - Parameter completionHandler: a completion handler, passed a value that either indicates
    ///     success (with an associated `Connection`) or failure (with an associated `Error`)
    public func withConnection(completionHandler: @escaping (Result<Connection, Error>) -> Void) {
        
        acquireConnection {
            [weak self] // avoid cycle: ConnectionPool -> Request -> completionHandler -> ConnectionPool
            result in
            
            do {
                let connection = try result.get()
                
                defer {
                    self?.releaseConnection(connection)
                }
                
                completionHandler(.success(connection))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Gets performance metrics for this `ConnectionPool`.
    ///
    /// The returned metrics describe `ConnectionPool` performance for the period starting when
    /// the metrics were last reset (or when this `ConnectionPool` was initialized, if the metrics
    /// have never been reset) and ending at the current moment in time.
    ///
    /// Performance metrics can also be periodically logged. See
    /// `ConnectionPoolConfiguration.metricsLoggingInterval`.
    ///
    /// - Parameter reset: whether to reset the metrics
    /// - Returns: the metrics
    @discardableResult public func computeMetrics(reset: Bool) -> ConnectionPoolMetrics {
        
        return threadsafe {
            
            let averageTimeToAcquireConnection = (successfulRequests == 0) ?
                0.0 : (successfulRequestsTime / Double(successfulRequests))
            
            let metrics = ConnectionPoolMetrics(
                periodBeginning: metricsPeriodBeginning,
                periodEnding: Date(),
                connectionPoolConfiguration: _connectionPoolConfiguration,
                successfulRequests: successfulRequests,
                unsuccessfulRequestsTooBusy: unsuccessfulRequestsTooBusy,
                unsuccessfulRequestsTimedOut: unsuccessfulRequestsTimedOut,
                unsuccessfulRequestsError: unsuccessfulRequestsError,
                averageTimeToAcquireConnection: averageTimeToAcquireConnection,
                minimumPendingRequests: minimumPendingRequests,
                maximumPendingRequests: maximumPendingRequests,
                connectionsAtStartOfPeriod: connectionsAtStartOfMetricsPeriod,
                connectionsAtEndOfPeriod: pooledConnections.count,
                connectionsCreated: connectionsCreated,
                allocatedConnectionsClosedByRequestor: allocatedConnectionsClosedByRequestor,
                allocatedConnectionsTimedOut: allocatedConnectionsTimedOut)
            
            if reset {
                metricsPeriodBeginning = Date()
                successfulRequests = 0
                successfulRequestsTime = 0.0
                unsuccessfulRequestsTooBusy = 0
                unsuccessfulRequestsTimedOut = 0
                unsuccessfulRequestsError = 0
                minimumPendingRequests = pendingRequests.count
                maximumPendingRequests = pendingRequests.count
                connectionsAtStartOfMetricsPeriod = pooledConnections.count
                connectionsCreated = 0
                allocatedConnectionsClosedByRequestor = 0
                allocatedConnectionsTimedOut = 0
            }
            
            return metrics
        }
    }
    
    /// Whether this `ConnectionPool` is closed.
    public var isClosed: Bool {
        return threadsafe { _isClosed }
    }
    
    /// Closes this `ConnectionPool`.
    ///
    /// Any pending requests for connections are canceled.
    ///
    /// If `force` is `true`, all `Connection` instances in this `ConnectionPool` are immediately
    /// forcibly closed.
    ///
    /// If `force` is false, only the unallocated `Connection` instances are immediately closed.
    /// The connections currently allocated to requests will be closed as those requests complete
    /// and the connections are released.
    ///
    /// Has no effect if this `ConnectionPool` is already closed.
    ///
    /// - Parameter force: whether to immediately forcibly close `Connection` instances currently
    ///     allocated to requests
    public func close(force: Bool = false) {
        
        threadsafe {
            if !_isClosed {
                
                log(.info, "Closing connection pool")
                _isClosed = true
                
                // Cancel all pending requests.
                for request in pendingRequests {
                    request.failure(PostgresError.connectionPoolClosed)
                }
                
                let pendingRequestsCount = pendingRequests.count
                pendingRequests.removeAll()
                minimumPendingRequests = 0
                
                log(.info, "Canceled \(pendingRequestsCount) pending request(s) for connections")
                
                // Destroy the pooled connections.
                for pooledConnection in pooledConnections {
                    if pooledConnection.state == .allocated && !force {
                        log(.info, "\(pooledConnection.connection) is allocated; will be closed when released")
                    } else {
                        destroyPooledConnection(pooledConnection)
                        log(.info, "Closed \(pooledConnection.connection)")
                    }
                }
            }
        }
    }
    
    deinit {
        Postgres.logger.info("Deinitializing connection pool")
        close(force: true)
    }
    
    
    //
    // MARK: Internal state
    //
    
    // Backs the like-named computed properties.
    private var _connectionPoolConfiguration: ConnectionPoolConfiguration
    private var _isClosed = false
    
    // The connections in the pool.
    private var pooledConnections = Set<PooledConnection>()
    
    // The pending requests for connections, oldest first.
    private var pendingRequests = [Request]()
    
    // Accumulators for connection pool metrics (see ConnectionPoolMetrics).
    private var metricsPeriodBeginning = Date()
    private var successfulRequests = 0
    private var successfulRequestsTime = 0.0 // in seconds
    private var unsuccessfulRequestsTooBusy = 0
    private var unsuccessfulRequestsTimedOut = 0
    private var unsuccessfulRequestsError = 0
    private var minimumPendingRequests = 0
    private var maximumPendingRequests = 0
    private var connectionsAtStartOfMetricsPeriod = 0
    private var connectionsCreated = 0
    private var allocatedConnectionsClosedByRequestor = 0
    private var allocatedConnectionsTimedOut = 0
    
    // The number of times connectionPoolConfiguration has changed.
    private var connectionPoolConfigurationChangeCount = 0
    
    
    //
    // MARK: Implementation
    //
    
    /// Caller responsible for threadsafety.
    private func releaseConnection(_ connection: Connection, timedOut: Bool) {
        
        // Verify the connection is in the pool.
        guard let pooledConnection = pooledConnections.first(
            where: { $0.connection === connection }) else {
                
                // The connection is *not* in the pool.  That could be because the pool was
                // forcibly closed.  That's OK.
                if _isClosed {
                    return
                }
                
                // Or perhaps the previous allocation timed out, in which case the connection
                // is closed.  That's also OK.
                if connection.isClosed {
                    return
                }
                
                // Otherwise, the connection doesn't belong to this pool.  Log a warning and close
                // the connection.
                abruptlyCloseConnection(connection)
                log(.warning, "\(connection) was not in connection pool; closed")
                
                return
        }
        
        // If the connection pool is closed, close the connection and remove it from the pool.
        if _isClosed {
            destroyPooledConnection(pooledConnection)
            log(.info, "Closed \(connection)")
            
        // If the current allocation has timed out, close the connection and remove it from the pool.
        } else if timedOut {
            allocatedConnectionsTimedOut += 1
            destroyPooledConnection(pooledConnection)
            log(.fine, "\(connection) timed out; connection closed")
            
        // If the connection is unallocated, the caller is trying to release a connection that was
        // already released.  Log a warning, close the connection, and remove it from the pool.
        } else if pooledConnection.state == .unallocated {
            destroyPooledConnection(pooledConnection)
            log(.warning, "\(connection) was already released; connection closed")
            
        // If the connection is closed, remove it from the pool.
        } else if connection.isClosed {
            allocatedConnectionsClosedByRequestor += 1
            destroyPooledConnection(pooledConnection)
            log(.fine, "\(connection) was closed; connection removed from connection pool")
            
        // If the connection has a transaction underway, log a warning, close the connection, and
        // remove it from the pool.
        } else if connection.transactionStatus != .idle {
            destroyPooledConnection(pooledConnection)
            log(.warning, "\(connection) was not committed or rolled back; connection closed")
            
        // Finally, the "normal" case.  Release the connection back to the pool.
        } else {
            pooledConnection.state = .unallocated
            log(.finer, "\(connection) released to connection pool")
        }
        
        allocateConnections() // see if we can fulfill any requests
    }
    
    private func allocateConnections() {
        
        async { // since creating a new connection is blocking
            self.threadsafe {
                
                while !self.pendingRequests.isEmpty {
                    
                    do {
                        // Is there a connection to allocate?
                        guard let pooledConnection = try self.findOrCreatePooledConnection() else {
                            break // can't allocate any more connections at this time
                        }
                        
                        // Yes.  Allocate it and schedule a timeout for releasing it.
                        pooledConnection.state = .allocated
                        self.scheduleTimeoutOfAllocatedConnection(pooledConnection)
                        
                        // Dequeue the oldest request.
                        let request = self.pendingRequests.removeFirst()
                        
                        // Update the metrics accumulators.
                        let elapsedTime = Date().timeIntervalSince(request.submitted)
                        self.successfulRequests += 1
                        self.successfulRequestsTime += elapsedTime
                        
                        // Execute the request's completion handler.
                        self.log(.finer, "\(pooledConnection.connection) acquired (\(Int(elapsedTime * 1000)) ms)")
                        request.success(pooledConnection.connection)
                    } catch {
                        // Dequeue the oldest request.  We signal the error by executing its
                        // completion handler.
                        let request = self.pendingRequests.removeFirst()
                        
                        // Update the metrics accumulators.
                        self.unsuccessfulRequestsError += 1
                        
                        // Execute the request's completion handler.
                        self.log(.warning, "Request for connection failed with error: \(error)")
                        request.failure(error)
                    }
                }
                
                self.minimumPendingRequests =
                    min(self.minimumPendingRequests, self.pendingRequests.count)
                
                // Never exceed the configured maximum number of connections.
                precondition(self.pooledConnections.count <=
                    self._connectionPoolConfiguration.maximumConnections)
                
                // Don't stop if there are pending requests that can be fulfilled at this time.
                precondition(
                    self.pendingRequests.isEmpty ||
                        (self.pooledConnections.count == self._connectionPoolConfiguration.maximumConnections &&
                            self.pooledConnections.first(where: { $0.state == .unallocated }) == nil))
            }
        }
    }
    
    /// Caller responsible for threadsafety.
    private func findOrCreatePooledConnection() throws -> PooledConnection? {
        
        var pooledConnection = earliestUnallocatedPooledConnection()
        
        if pooledConnection == nil &&
            pooledConnections.count < _connectionPoolConfiguration.maximumConnections {
            
            let connection = try Connection(configuration: connectionConfiguration,
                                            delegate: connectionDelegate)
            
            pooledConnection = PooledConnection(connection: connection)
            pooledConnections.insert(pooledConnection!)
            connectionsCreated += 1
            log(.finer, "\(connection) created")
        }
        
        return pooledConnection
    }
    
    /// Caller responsible for threadsafety.
    private func earliestUnallocatedPooledConnection() -> PooledConnection? {
        return pooledConnections.reduce(
            nil,
            {
                if $1.state == .unallocated &&
                    $1.stateChanged < ($0?.stateChanged ?? Date.distantFuture) {
                    return $1
                } else {
                    return $0
                }
            })
    }
    
    /// Caller responsible for threadsafety.
    private func destroyPooledConnection(_ pooledConnection: PooledConnection) {
        pooledConnection.state = .unallocated
        pooledConnections.remove(pooledConnection)
        abruptlyCloseConnection(pooledConnection.connection)
    }
    
    private func abruptlyCloseConnection(_ connection: Connection) {
        async { // since closing a connection is blocking
            connection.closeAbruptly()
        }
    }
    
    /// Caller responsible for threadsafety.
    private func scheduleTimeoutOfPendingRequest(_ request: Request) {
        
        // Do requests for connections time out?
        if let pendingRequestTimeout = _connectionPoolConfiguration.pendingRequestTimeout {
            
            // Yes.  Compute the deadline.
            let deadline = DispatchWallTime.now() + .seconds(pendingRequestTimeout)
            
            // And schedule the timeout.
            _connectionPoolConfiguration.dispatchQueue.asyncAfter(wallDeadline: deadline) {
                [weak self, weak request] in
                
                guard
                    let self = self,
                    let request = request else {
                        return
                }
                
                self.threadsafe {
                    // If the request is still pending...
                    if self.pendingRequests.contains(where: { $0 === request }) {
                        
                        // Cancel it.
                        self.pendingRequests.removeAll(where: { $0 === request })
                        
                        // Update the metrics accumulators.
                        self.unsuccessfulRequestsTimedOut += 1
                        
                        // Execute the request's completion handler.
                        self.log(.fine, "Request for connection timed out")
                        request.failure(PostgresError.timedOutAcquiringConnection)
                    }
                }
            }
        }
    }
    
    /// Caller responsible for threadsafety.
    private func scheduleTimeoutOfAllocatedConnection(_ pooledConnection: PooledConnection) {
        
        // Do allocations of connections time out?
        if let allocatedConnectionTimeout = _connectionPoolConfiguration.allocatedConnectionTimeout {
            
            // Yes.  Compute the deadline.
            let deadline = DispatchWallTime.now() + .seconds(allocatedConnectionTimeout)
            
            // And schedule the timeout.
            let connection = pooledConnection.connection
            let stateChanged = pooledConnection.stateChanged
            
            _connectionPoolConfiguration.dispatchQueue.asyncAfter(wallDeadline: deadline) {
                [weak self, weak pooledConnection, weak connection] in
                
                guard
                    let self = self,
                    let pooledConnection = pooledConnection,
                    let connection = connection else {
                        return
                }
                
                self.threadsafe {
                    // If the connection is still allocated...
                    if pooledConnection.connection === connection &&
                        pooledConnection.state == .allocated &&
                        pooledConnection.stateChanged == stateChanged {
                        
                        // Release it.
                        self.releaseConnection(connection, timedOut: true)
                    }
                }
            }
        }
    }
    
    private func scheduleMetricsLogging() {
        
        threadsafe {
            // Is periodic logging of the metrics enabled?
            if let interval = _connectionPoolConfiguration.metricsLoggingInterval {
                
                // Yes.  Compute when they should next be logged.  For example, if the interval is
                // every 30 minutes, log them at the start of each hour and at 30 minutes after each
                // hour.  If the interval is every 6 hours, log them at midnight, 06:00, noon, and
                // 18:00 (all times UTC).
                let now = Date()
                let nowSeconds = Int(now.timeIntervalSinceReferenceDate)
                
                let midnightUtc = ISO8601.enUsPosixUtcCalendar.startOfDay(for: now)
                let midnightUtcSeconds = Int(midnightUtc.timeIntervalSinceReferenceDate)
                
                let intervalSeconds = max(interval, 1) // prevent division by 0
                
                let nextSeconds = midnightUtcSeconds +
                    (((nowSeconds - midnightUtcSeconds) / intervalSeconds) + 1) * intervalSeconds
                
                let next = Date(timeIntervalSinceReferenceDate: Double(nextSeconds))
                
                let deadline = DispatchWallTime.now() +
                    .milliseconds(Int(next.timeIntervalSinceNow * 1000))
                
                let connectionPoolChangeCountWhenScheduled = connectionPoolConfigurationChangeCount
                let reset = self._connectionPoolConfiguration.metricsResetWhenLogged
                
                // Schedule it.
                _connectionPoolConfiguration.dispatchQueue.asyncAfter(wallDeadline: deadline) {
                    [weak self] in
                    
                    guard let self = self else {
                        return
                    }
                    
                    guard self.connectionPoolConfigurationChangeCount ==
                        connectionPoolChangeCountWhenScheduled else {
                            // The connectionPoolConfiguration was updated, causing metrics logging
                            // to be rescheduled (with a possibly-changed metricsLoggingInterval).
                            // Nothing to do here.
                            return
                    }
                    
                    if !self.isClosed {
                        let metrics = self.computeMetrics(reset: reset)
                        Postgres.logger.info(metrics.description)
                        
                        self.scheduleMetricsLogging() // schedule the next iteration
                    }
                }
            }
        }
    }
    
    
    //
    // MARK: Logging
    //
    
    /// Logs a messsage.
    ///
    /// The message context is a short summary of connection pool performance.  For example:
    ///
    ///     ConnectionPool(12/20 92% 13ms)
    ///
    /// indicates there are 20 connections in the pool, of which 12 are currently allocated.
    /// 92% of requests of connections have been successfully fulfilled, after an average wait
    /// time of 13 milliseconds.
    ///
    /// Caller responsible for threadsafety.
    private func log(_ level: LogLevel,
                     _ message: CustomStringConvertible,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        
        let allocatedCount = pooledConnections.filter({ $0.state == .allocated }).count
        let connectionCount = pooledConnections.count
        
        let totalRequests =
                successfulRequests +
                unsuccessfulRequestsTooBusy +
                unsuccessfulRequestsTimedOut +
                unsuccessfulRequestsError
        
        let successfulRequestsPercent = (totalRequests == 0) ? 100.0 :
            100.0 * Double(successfulRequests) / Double(totalRequests)
        
        let averageTimeToAcquireConnection = (successfulRequests == 0) ? 0.0 :
            successfulRequestsTime / Double(successfulRequests) * 1000.0 // milliseconds
        
        let context = String(format: "ConnectionPool(%d/%d %.0f%% %.0fms)",
                             allocatedCount,
                             connectionCount,
                             successfulRequestsPercent,
                             averageTimeToAcquireConnection)
        
        Postgres.logger.log(level: level,
                            message: message,
                            context: context,
                            file: file,
                            function: function,
                            line: line)
    }
    
    
    //
    // MARK: Threadsafety
    //
    
    private let connectionPoolLock = NSLock()
    
    private func threadsafe<T>(_ critical: () -> T) -> T {
        connectionPoolLock.lock()
        defer { connectionPoolLock.unlock() }
        return critical()
    }
    
    
    //
    // MARK: Async
    //
    
    private func async(_ operation: @escaping () -> Void) {
        _connectionPoolConfiguration.dispatchQueue.async {
            operation()
        }
    }
    
    
    //
    // MARK: Nested types
    //
    
    /// A request for a connection.
    private class Request {
        
        fileprivate init(connectionPool: ConnectionPool,
                         completionHandler: @escaping (Result<Connection, Error>) -> Void) {
            
            self.connectionPool = connectionPool
            self.completionHandler = completionHandler
        }
        
        private weak var connectionPool: ConnectionPool?
        private let completionHandler: (Result<Connection, Error>) -> Void
        
        fileprivate let submitted = Date()
        
        fileprivate func success(_ connection: Connection) {
            
            let completionHandler = self.completionHandler // to not capture self below
            
            connectionPool?.async {
                completionHandler(.success(connection))
            }
        }
        
        fileprivate func failure(_ error: Error) {
            
            let completionHandler = self.completionHandler // to not capture self below
            
            connectionPool?.async {
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Wraps a `Connection` in this `ConnectionPool` to track whether it is currently allocated.
    private class PooledConnection: Hashable {
        
        fileprivate enum State {
            case unallocated
            case allocated
        }
        
        fileprivate init(connection: Connection) {
            self.connection = connection
        }
        
        fileprivate let connection: Connection
        
        fileprivate var state: State = .unallocated {
            didSet {
                stateChanged = Date()
            }
        }
        
        fileprivate private(set) var stateChanged = Date()
        
        fileprivate func hash(into hasher: inout Hasher) {
            hasher.combine(connection.id)
        }
        
        fileprivate static func == (lhs: PooledConnection, rhs: PooledConnection) -> Bool {
            return lhs.connection.id == rhs.connection.id
        }
    }
}

// EOF
