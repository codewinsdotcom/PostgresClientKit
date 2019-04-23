//
//  ConnectionTest.swift
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

/// Tests Connection.
class ConnectionTest: PostgresClientKitTestCase {
    
    func testCreateConnection() throws {
        
        // Network error
        var configuration = terryConnectionConfiguration()
        configuration.host = "256.0.0.0"
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.socketError = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        // Non-SSL
        configuration = terryConnectionConfiguration()
        configuration.ssl = false
        XCTAssertNoThrow(try Connection(configuration: configuration).close())
        
        // SSL
        configuration = terryConnectionConfiguration()
        configuration.ssl = true // (the default)
        XCTAssertNoThrow(try Connection(configuration: configuration).close())
        

        // Authenticate: trust required, trust supplied
        configuration = terryConnectionConfiguration()
        XCTAssertNoThrow(try Connection(configuration: configuration).close())

        // Authenticate: trust required, cleartextPassword supplied
        configuration = terryConnectionConfiguration()
        configuration.credential = .cleartextPassword(password: "wrong-credential-type")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.trustCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        // Authenticate: trust required, md5Password supplied
        configuration = terryConnectionConfiguration()
        configuration.credential = .md5Password(password: "wrong-credential-type")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.trustCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }

        // Authenticate: cleartextPassword required, trust supplied
        configuration = charlieConnectionConfiguration()
        configuration.credential = .trust
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.cleartextPasswordCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        // Authenticate: cleartextPassword required, cleartextPassword supplied
        configuration = charlieConnectionConfiguration()
        XCTAssertNoThrow(try Connection(configuration: configuration).close())
        
        // Authenticate: cleartextPassword required, cleartextPassword supplied, incorrect password
        configuration = charlieConnectionConfiguration()
        configuration.credential = .cleartextPassword(password: "wrong-password")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.sqlError = error else {
                return XCTFail(String(describing: error))
            }
        }

        // Authenticate: cleartextPassword required, md5Password supplied
        configuration = charlieConnectionConfiguration()
        configuration.credential = .md5Password(password: "wrong-credential-type")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.cleartextPasswordCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        // Authenticate: md5Password required, trust supplied
        configuration = maryConnectionConfiguration()
        configuration.credential = .trust
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.md5PasswordCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }

        // Authenticate: md5Password required, cleartextPassword supplied
        configuration = maryConnectionConfiguration()
        configuration.credential = .cleartextPassword(password: "wrong-credential-type")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.md5PasswordCredentialRequired = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        // Authenticate: md5Password required, md5Password supplied
        configuration = maryConnectionConfiguration()
        XCTAssertNoThrow(try Connection(configuration: configuration).close())
        
        // Authenticate: md5Password required, md5Password supplied, incorrect password
        configuration = maryConnectionConfiguration()
        configuration.credential = .md5Password(password: "wrong-password")
        XCTAssertThrowsError(try Connection(configuration: configuration)) { error in
            guard case PostgresError.sqlError = error else {
                return XCTFail(String(describing: error))
            }
        }
    }
    
    func testConnectionLifecycle() {
        
        do {
            let configuration = maryConnectionConfiguration()
            
            let connection1 = try Connection(configuration: configuration)
            let connection2 = try Connection(configuration: configuration)
            
            XCTAssertNotEqual(connection1.id, connection2.id)
            XCTAssertEqual(connection1.id, connection1.description)
            
            XCTAssertNil(connection1.delegate)

            XCTAssertFalse(connection1.isClosed)
            XCTAssertFalse(connection2.isClosed)
            
            connection1.close()
            XCTAssertTrue(connection1.isClosed)
            XCTAssertFalse(connection2.isClosed)
            
            connection1.close()
            XCTAssertTrue(connection1.isClosed)
            XCTAssertFalse(connection2.isClosed)
            
            connection2.close()
            XCTAssertTrue(connection1.isClosed)
            XCTAssertTrue(connection2.isClosed)
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    // TODO: delegate
}

// EOF
