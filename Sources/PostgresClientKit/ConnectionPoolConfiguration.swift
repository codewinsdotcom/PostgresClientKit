//
//  ConnectionPoolConfiguration.swift
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

/// The configuration of a `ConnectionPool`.
public struct ConnectionPoolConfiguration {
    
    /// Creates a `ConnectionPoolConfiguration`.
    public init() { }
    
    /// The maximum number of connections in the `ConnectionPool`.  Defaults to `10`.
    public var maximumConnections = 10
    
    /// The maximum size of the backlog of requests for connections, or `nil` for no limit.
    /// Defaults to `nil`.
    public var maximumPendingRequests: Int? = nil
    
    /// The maximum time, in seconds, that requests for connections will wait before timing out,
    /// or `nil` for no timeout.  Defaults to `nil`.
    public var pendingRequestTimeout: Int? = nil
    
    /// The maximum time, in seconds, that connections allocated to requests can be used before
    /// timing out, or `nil` for no timeout.  Defaults to `nil`.
    public var allocatedConnectionTimeout: Int? = nil
    
    /// The `DispatchQueue` on which completion handlers for
    /// `ConnectionPool.acquireConnection(completionHandler:)` and
    /// `ConnectionPool.withConnection(completionHandler:)` are executed.
    ///
    /// This dispatch queue is also used for asynchronous tasks internally performed by the
    /// `ConnectionPool`, such as managing timeouts and periodic logging of performance metrics.
    ///
    /// Defaults to `DispatchQueue.global()`.
    public var dispatchQueue = DispatchQueue.global()
    
    /// The interval, in seconds, between periodic logging of `ConnectionPool` performance metrics,
    /// or `nil` to not log performance metrics.
    ///
    /// For example, a value of `3600` causes metrics to be logged once an hour (at the start of
    /// the hour).  A value of `21600` causes metrics to be logged every 6 hours (at midnight,
    /// 06:00, noon, and 18:00 UTC).
    ///
    /// Metrics are logged with `LogLevel.info`.
    ///
    /// Defaults to `3600`.
    ///
    /// - SeeAlso: `ConnectionPool.computeMetrics(reset:)`
    public var metricsLoggingInterval: Int? = 3600
    
    /// Whether the `ConnectionPool` performance metrics are reset each time they are logged.
    /// Defaults to `true`.
    public var metricsResetWhenLogged = true
}

// EOF
