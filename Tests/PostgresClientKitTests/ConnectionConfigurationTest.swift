//
//  ConnectionConfigurationTest.swift
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

/// Tests ConnectionConfiguration.
class ConnectionConfigurationTest: PostgresClientKitTestCase {
    
    func test() {

        var configuration = ConnectionConfiguration()
        XCTAssertEqual(configuration.host, "localhost")
        XCTAssertEqual(configuration.port, 5432)
        XCTAssertEqual(configuration.ssl, true)
        XCTAssertEqual(configuration.socketTimeout, 0)
        XCTAssertEqual(configuration.database, "postgres")
        XCTAssertEqual(configuration.user, "")
        
        if case .trust = configuration.credential { } else {
            XCTFail("credential \(configuration.credential)")
        }
        
        configuration.host = "postgres.example.com"
        configuration.port = 54321
        configuration.ssl = false
        configuration.socketTimeout = 30
        configuration.database = "example"
        configuration.user = "bob.loblaw"
        configuration.credential = .cleartextPassword(password: "welcome1")
        
        XCTAssertEqual(configuration.host, "postgres.example.com")
        XCTAssertEqual(configuration.port, 54321)
        XCTAssertEqual(configuration.ssl, false)
        XCTAssertEqual(configuration.socketTimeout, 30)
        XCTAssertEqual(configuration.database, "example")
        XCTAssertEqual(configuration.user, "bob.loblaw")
        
        if case .cleartextPassword(password: "welcome1") = configuration.credential { } else {
            XCTFail("credential \(configuration.credential)")
        }
    }
}

// EOF
