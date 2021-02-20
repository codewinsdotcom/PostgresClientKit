//
//  ConnectionPoolMetrics.swift
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

/// Performance metrics for a `ConnectionPool`.
///
/// - SeeAlso: `ConnectionPool.computeMetrics(reset:)`
public struct ConnectionPoolMetrics: CustomStringConvertible {
    
    /// The start of the time period described by this `ConnectionPoolMetrics` instance.
    public let periodBeginning: Date
    
    /// The end of the time period described by this `ConnectionPoolMetrics` instance.
    public let periodEnding: Date
    
    /// The `ConnectionPoolConfiguration` at the end of the period.
    public let connectionPoolConfiguration: ConnectionPoolConfiguration
    
    /// The number of requests for connections for which connections were successfully allocated.
    public let successfulRequests: Int
    
    /// The number of requests for connections that failed because the request backlog was too
    /// large.
    ///
    /// - SeeAlso: `ConnectionPoolConfiguration.maximumPendingRequests`
    public let unsuccessfulRequestsTooBusy: Int
    
    /// The number of requests for connections that failed because connections were not allocated
    /// before the requests timed out.
    ///
    /// - SeeAlso: `ConnectionPoolConfiguration.pendingRequestTimeout`
    public let unsuccessfulRequestsTimedOut: Int
    
    /// The number of requests for connections that failed because errors occurred.
    public let unsuccessfulRequestsError: Int
    
    /// The average time, in seconds, that requests for connections waited before connections were
    /// successfully allocated.
    public let averageTimeToAcquireConnection: TimeInterval
    
    /// The minimum size of the backlog of requests for connections.
    public let minimumPendingRequests: Int
    
    /// The maximum size of the backlog of requests for connections.
    public let maximumPendingRequests: Int
    
    /// The number of connections in the connection pool at the start of the period.
    public let connectionsAtStartOfPeriod: Int
    
    /// The number of connections in the connection pool at the end of the period.
    public let connectionsAtEndOfPeriod: Int
    
    /// The number of new connections added to the connection pool.
    public let connectionsCreated: Int
    
    /// The number of connections that, having been allocated to requests, were closed by the
    /// requestors before being released, causing them to be discarded from the connection pool.
    public let allocatedConnectionsClosedByRequestor: Int
    
    /// The number of connections that, having been allocated to requests, were not released by
    /// the requestors before they timed out, causing them to be closed and discarded from the
    /// connection pool.
    ///
    /// - SeeAlso: `ConnectionPoolConfiguration.allocatedConnectionTimeout`
    public let allocatedConnectionsTimedOut: Int
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A formatted string representation of this `ConnectionPoolMetrics` instance.
    public var description: String {
        
        var s = ""
        
        // The metrics...
        do {
            let periodBeginningString = timestampString(periodBeginning)
            let periodEndingString = timestampString(periodEnding)
            
            let totalRequests =
                    successfulRequests +
                    unsuccessfulRequestsTooBusy +
                    unsuccessfulRequestsTimedOut +
                    unsuccessfulRequestsError
            
            let successfulRequestsString = intString(successfulRequests)
            let unsuccessfulRequestsTooBusyString = intString(unsuccessfulRequestsTooBusy)
            let unsuccessfulRequestsTimedOutString = intString(unsuccessfulRequestsTimedOut)
            let unsuccessfulRequestsErrorString = intString(unsuccessfulRequestsError)
            let totalRequestsString = intString(totalRequests)
            
            let successfulRequestsPercent = (totalRequests == 0) ? "     " :
                percentString(100.0 * Double(successfulRequests) / Double(totalRequests))
            
            let unsuccessfulRequestsTooBusyPercent = (totalRequests == 0) ? "     " :
                percentString(100.0 * Double(unsuccessfulRequestsTooBusy) / Double(totalRequests))
            
            let unsuccessfulRequestsTimedOutPercent = (totalRequests == 0) ? "     " :
                percentString(100.0 * Double(unsuccessfulRequestsTimedOut) / Double(totalRequests))
            
            let unsuccessfulRequestsErrorPercent = (totalRequests == 0) ? "     " :
                percentString(100.0 * Double(unsuccessfulRequestsError) / Double(totalRequests))
            
            let totalRequestsPercent = (totalRequests == 0) ? "     " :
                percentString(100.0 * Double(totalRequests) / Double(totalRequests))
            
            let minimumPendingRequestsString = intString(minimumPendingRequests)
            let maximumPendingRequestsString = intString(maximumPendingRequests)
            
            let averageTimeToAcquireConnectionString = intString(
                Int((averageTimeToAcquireConnection * 1000.0).rounded(.toNearestOrEven)))
            
            let connectionsAtStartOfPeriodString = intString(connectionsAtStartOfPeriod)
            let connectionsAtEndOfPeriodString = intString(connectionsAtEndOfPeriod)
            let connectionsCreatedString = intString(connectionsCreated)
            let allocatedConnectionsClosedByRequestorString = intString(allocatedConnectionsClosedByRequestor)
            let allocatedConnectionsTimedOutString = intString(allocatedConnectionsTimedOut)
            
            s += """
            Connection pool metrics
            
                For the period from  \(periodBeginningString)
                                 to  \(periodEndingString)
            
                Requests for connections
                    Successful           \(successfulRequestsString          ) (\(successfulRequestsPercent          )%)
                    Failed - too busy    \(unsuccessfulRequestsTooBusyString ) (\(unsuccessfulRequestsTooBusyPercent )%)
                    Failed - timed out   \(unsuccessfulRequestsTimedOutString) (\(unsuccessfulRequestsTimedOutPercent)%)
                    Failed - error       \(unsuccessfulRequestsErrorString   ) (\(unsuccessfulRequestsErrorPercent   )%)
                    Total                \(totalRequestsString               ) (\(totalRequestsPercent               )%)
            
                Minimum pending requests \(minimumPendingRequestsString)
                Maximum pending requests \(maximumPendingRequestsString)
            
                Average time to acquire connection        \(averageTimeToAcquireConnectionString       ) ms
            
                Connections at start of period            \(connectionsAtStartOfPeriodString           )
                Connections at end of period              \(connectionsAtEndOfPeriodString             )
                Connections created                       \(connectionsCreatedString                   )
                Allocated connections closed by requestor \(allocatedConnectionsClosedByRequestorString)
                Allocated connections timed out           \(allocatedConnectionsTimedOutString         )\n\n
            """
        }
        
        // The configuration...
        do { // separate block to avoid variable name conflicts
            let maximumConnectionsString = intString(connectionPoolConfiguration.maximumConnections)
            
            let maximumPendingRequestsString = (connectionPoolConfiguration.maximumPendingRequests == nil) ?
                "   no limit" : intString(connectionPoolConfiguration.maximumPendingRequests!)
            
            let pendingRequestTimeoutString = (connectionPoolConfiguration.pendingRequestTimeout == nil) ?
                "       none" : (intString(connectionPoolConfiguration.pendingRequestTimeout!) + " s")
            
            let allocatedConnectionTimeoutString = (connectionPoolConfiguration.allocatedConnectionTimeout == nil) ?
                "       none" : (intString(connectionPoolConfiguration.allocatedConnectionTimeout!) + " s")
            
            let metricsLoggingIntervalString = (connectionPoolConfiguration.metricsLoggingInterval == nil) ?
                "   disabled" : (intString(connectionPoolConfiguration.metricsLoggingInterval!) + " s")
            
            let metricsResetWhenLoggedString = connectionPoolConfiguration.metricsResetWhenLogged ?
                "       true" :
                "      false"
            
            s += """
            Connection pool configuration
                Maximum connections                   \(maximumConnectionsString        )
                Maximum pending requests              \(maximumPendingRequestsString    )
                Pending request timeout               \(pendingRequestTimeoutString     )
                Allocated connection timeout          \(allocatedConnectionTimeoutString)
                Metrics logging interval              \(metricsLoggingIntervalString    )
                Metrics reset when logged             \(metricsResetWhenLoggedString    )\n\n
            """
        }
        
        return s
    }
    
    
    //
    // MARK: Implementation details
    //
    
    private static let timestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Postgres.enUsPosixLocale
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        df.timeZone = ISO8601.utcTimeZone
        return df
    }()
    
    private static let enUsLocale = Locale(identifier: "en_US") // for grouping separators
    
    private func timestampString(_ date: Date) -> String {
        return ConnectionPoolMetrics.timestampFormatter.string(from: date)
    }
    
    private func intString(_ int: Int) -> String {
        return String(format: "%11ld", locale: ConnectionPoolMetrics.enUsLocale, int)
    }
    
    private func percentString(_ double: Double) -> String {
        return String(format: "%5.1f", locale: ConnectionPoolMetrics.enUsLocale, double)
    }
}

// EOF
