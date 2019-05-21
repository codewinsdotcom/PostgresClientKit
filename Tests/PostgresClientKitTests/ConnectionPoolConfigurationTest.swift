//
//  ConnectionPoolConfigurationTest.swift
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

/// Tests ConnectionPoolConfiguration.
class ConnectionPoolConfigurationTest: PostgresClientKitTestCase {
    
    func test() {
        
        var configuration = ConnectionPoolConfiguration()
        XCTAssertEqual(configuration.maximumConnections, 10)
        XCTAssertNil(configuration.maximumPendingRequests)
        XCTAssertNil(configuration.pendingRequestTimeout)
        XCTAssertNil(configuration.allocatedConnectionTimeout)
        XCTAssertEqual(configuration.dispatchQueue, DispatchQueue.global())
        XCTAssertEqual(configuration.metricsLoggingInterval, 3600)
        XCTAssertEqual(configuration.metricsResetWhenLogged, true)
        
        configuration.maximumConnections = 20
        configuration.maximumPendingRequests = 100
        configuration.pendingRequestTimeout = 5
        configuration.allocatedConnectionTimeout = 30
        configuration.dispatchQueue = DispatchQueue.global(qos: .background)
        configuration.metricsLoggingInterval = 21600
        configuration.metricsResetWhenLogged = false
        
        XCTAssertEqual(configuration.maximumConnections, 20)
        XCTAssertEqual(configuration.maximumPendingRequests, 100)
        XCTAssertEqual(configuration.pendingRequestTimeout, 5)
        XCTAssertEqual(configuration.allocatedConnectionTimeout, 30)
        XCTAssertEqual(configuration.dispatchQueue, DispatchQueue.global(qos: .background))
        XCTAssertEqual(configuration.metricsLoggingInterval, 21600)
        XCTAssertEqual(configuration.metricsResetWhenLogged, false)
    }
}

// EOF
