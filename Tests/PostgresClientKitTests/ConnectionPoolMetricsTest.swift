//
//  ConnectionPoolMetricsTest.swift
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

@testable import PostgresClientKit
import XCTest

/// Tests ConnectionPoolMetrics.
class ConnectionPoolMetricsTest: PostgresClientKitTestCase {
    
    func test() {
        
        let periodBeginning = Date(timeIntervalSince1970: 0)
        let periodEnding = Date(timeIntervalSinceReferenceDate: 0)
        var configuration = ConnectionPoolConfiguration()
        
        var metrics = ConnectionPoolMetrics(
            periodBeginning: periodBeginning,
            periodEnding: periodEnding,
            connectionPoolConfiguration: configuration,
            successfulRequests:  111_111_111,
            unsuccessfulRequestsTooBusy: 222_222_222,
            unsuccessfulRequestsTimedOut: 333_333_333,
            unsuccessfulRequestsError: 123_456_789,
            averageTimeToAcquireConnection: 0.1234,
            minimumPendingRequests: 222_333_444,
            maximumPendingRequests: 555_666_777,
            connectionsAtStartOfPeriod: 444_444_444,
            connectionsAtEndOfPeriod: 555_555_555,
            connectionsCreated: 666_666_666,
            allocatedConnectionsClosedByRequestor: 777_777_777,
            allocatedConnectionsTimedOut: 888_888_888)
        
        var description = """
        Connection pool metrics
        
            For the period from  1970-01-01T00:00:00Z
                             to  2001-01-01T00:00:00Z
        
            Requests for connections
                Successful           111,111,111 ( 14.1%)
                Failed - too busy    222,222,222 ( 28.1%)
                Failed - timed out   333,333,333 ( 42.2%)
                Failed - error       123,456,789 ( 15.6%)
                Total                790,123,455 (100.0%)
        
            Minimum pending requests 222,333,444
            Maximum pending requests 555,666,777
        
            Average time to acquire connection                123 ms
        
            Connections at start of period            444,444,444
            Connections at end of period              555,555,555
            Connections created                       666,666,666
            Allocated connections closed by requestor 777,777,777
            Allocated connections timed out           888,888,888
        
        Connection pool configuration
            Maximum connections                            10
            Maximum pending requests                 no limit
            Pending request timeout                      none
            Allocated connection timeout                 none
            Metrics logging interval                    3,600 s
            Metrics reset when logged                    true\n\n
        """
        
        XCTAssertEqual(String(describing: metrics), description)
        
        configuration.maximumConnections = 20
        configuration.maximumPendingRequests = 100
        configuration.pendingRequestTimeout = 5
        configuration.allocatedConnectionTimeout = 30
        configuration.dispatchQueue = DispatchQueue.global(qos: .background)
        configuration.metricsLoggingInterval = 21600
        configuration.metricsResetWhenLogged = false

        metrics = ConnectionPoolMetrics(
            periodBeginning: periodBeginning,
            periodEnding: periodEnding,
            connectionPoolConfiguration: configuration,
            successfulRequests: 111_111_111,
            unsuccessfulRequestsTooBusy: 222_222_222,
            unsuccessfulRequestsTimedOut: 333_333_333,
            unsuccessfulRequestsError: 123_456_789,
            averageTimeToAcquireConnection: 0.1234,
            minimumPendingRequests: 222_333_444,
            maximumPendingRequests: 555_666_777,
            connectionsAtStartOfPeriod: 444_444_444,
            connectionsAtEndOfPeriod: 555_555_555,
            connectionsCreated: 666_666_666,
            allocatedConnectionsClosedByRequestor: 777_777_777,
            allocatedConnectionsTimedOut: 888_888_888)
        
        description = """
        Connection pool metrics

            For the period from  1970-01-01T00:00:00Z
                             to  2001-01-01T00:00:00Z

            Requests for connections
                Successful           111,111,111 ( 14.1%)
                Failed - too busy    222,222,222 ( 28.1%)
                Failed - timed out   333,333,333 ( 42.2%)
                Failed - error       123,456,789 ( 15.6%)
                Total                790,123,455 (100.0%)

            Minimum pending requests 222,333,444
            Maximum pending requests 555,666,777

            Average time to acquire connection                123 ms

            Connections at start of period            444,444,444
            Connections at end of period              555,555,555
            Connections created                       666,666,666
            Allocated connections closed by requestor 777,777,777
            Allocated connections timed out           888,888,888

        Connection pool configuration
            Maximum connections                            20
            Maximum pending requests                      100
            Pending request timeout                         5 s
            Allocated connection timeout                   30 s
            Metrics logging interval                   21,600 s
            Metrics reset when logged                   false\n\n
        """

        XCTAssertEqual(String(describing: metrics), description)
    }
}

// EOF
