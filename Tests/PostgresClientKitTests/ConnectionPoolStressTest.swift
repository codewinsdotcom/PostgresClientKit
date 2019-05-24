//
//  ConnectionPoolStressTest.swift
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

import PostgresClientKit
import XCTest

/// Stress tests ConnectionPool.
class ConnectionPoolStressTest: PostgresClientKitTestCase {
    
    // Whether to perform the test.  Disabled by default, since this test is lengthy.
    let performTest = false

    /// Number of requests to submit.
    let requestCount = 1_000_000
    
    // Time between requests, in seconds.
    let interRequestTime = { Double.random(in: 0.0005..<0.0015) }

    func test() throws {
        guard performTest else { return }
        
        try createWeatherTable()
        
        var connectionPoolConfiguration = ConnectionPoolConfiguration()
        connectionPoolConfiguration.maximumConnections = 10
        connectionPoolConfiguration.maximumPendingRequests = 1000
        connectionPoolConfiguration.pendingRequestTimeout = 2
        connectionPoolConfiguration.allocatedConnectionTimeout = 30
        connectionPoolConfiguration.dispatchQueue = DispatchQueue.global()
        connectionPoolConfiguration.metricsLoggingInterval = 5
        connectionPoolConfiguration.metricsResetWhenLogged = false
        
        let pool = ConnectionPool(
            connectionPoolConfiguration: connectionPoolConfiguration,
            connectionConfiguration: terryConnectionConfiguration())
        
        for _ in 0..<requestCount {
            
            Thread.sleep(forTimeInterval: interRequestTime())
            
            pool.withConnection { result in
                do {
                    let connection = try result.get()
                    let statement = try connection.prepareStatement(text: "SELECT * FROM weather")
                    let cursor = try statement.execute()
                    
                    for row in cursor {
                        let columns = try row.get().columns
                        _ = try columns[0].string()
                        _ = try columns[1].int()
                        _ = try columns[2].int()
                        _ = try columns[3].optionalDecimal()
                        _ = try columns[4].date()
                    }
                } catch {
                    switch error {
                    case PostgresError.tooManyRequestsForConnections: break // reported in metrics
                    case PostgresError.timedOutAcquiringConnection: break   // reported in metrics
                    default: print(error)
                    }
                }
            }
        }
        
        print("<<< Submitted final request; stopping in 5 seconds >>>")
        Thread.sleep(forTimeInterval: 5.0)
        print(pool.computeMetrics(reset: false))
    }
}

// EOF
