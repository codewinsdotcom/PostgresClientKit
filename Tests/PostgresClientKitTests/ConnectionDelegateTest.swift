//
//  ConnectionDelegateTest.swift
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

/// Tests ConnectionDelegate.
class ConnectionDelegateTest: PostgresClientKitTestCase {
    
    func test() {
        
        class Delegate: ConnectionDelegate {
            
            var lastNotice: Notice? = nil
            var lastParameterStatus: (name: String, value: String)? = nil
            var lastNotification: (processId: UInt32, channel: String, payload: String)? = nil
            
            func connection(
                _ connection: Connection,
                didReceiveNotice notice: Notice) {
                
                XCTAssertNotNil(connection)
                lastNotice = notice
            }
            
            func connection(
                _ connection: Connection,
                didReceiveParameterStatus parameterStatus: (name: String, value: String)) {
                
                XCTAssertNotNil(connection)
                lastParameterStatus = parameterStatus
            }
            
            func connection(
                _ connection: Connection,
                didReceiveNotification notification: (processId: UInt32,
                channel: String,
                payload: String)) {
                XCTAssertNotNil(connection)
                lastNotification = notification
            }
        }
        
        do {
            let delegate = Delegate()
            let configuration = terryConnectionConfiguration()
            let connection = try Connection(configuration: configuration, delegate: delegate)
            
            // didReceiveNotice
            var text = "SET client_min_messages = debug5"
            var statement = try connection.prepareStatement(text: text)
            try statement.execute()
            XCTAssertNotNil(delegate.lastNotice)
            XCTAssertNotNil(delegate.lastNotice?.localizedSeverity) // locale sensitive
            XCTAssertEqual(delegate.lastNotice?.severity, "DEBUG")
            XCTAssertEqual(delegate.lastNotice?.code, "00000")
            XCTAssertNotNil(delegate.lastNotice?.message) // platform variant
            XCTAssertEqual(delegate.lastNotice?.file, "xact.c")
            XCTAssertNotNil(delegate.lastNotice?.line)
            XCTAssertEqual(delegate.lastNotice?.routine, "ShowTransactionStateRec")
            
            // didReceiveNotification
            text = "LISTEN foo"
            statement = try connection.prepareStatement(text: text)
            try statement.execute()
            text = "NOTIFY foo, 'bar'"
            statement = try connection.prepareStatement(text: text)
            try statement.execute()
            XCTAssert(delegate.lastNotification != nil)
            XCTAssertNotNil(delegate.lastNotification?.processId)
            XCTAssertEqual(delegate.lastNotification?.channel, "foo")
            XCTAssertEqual(delegate.lastNotification?.payload, "bar")
            
            // didReceiveParameterStatus
            text = "SET client_encoding = 'BIG5'"
            statement = try connection.prepareStatement(text: text)
            let operation = { try statement.execute() }
            XCTAssertThrowsError(try operation()) { error in
                guard case PostgresError.invalidParameterValue = error else {
                    return XCTFail(String(describing: error))
                }
            }
            XCTAssertNotNil(delegate.lastParameterStatus)
            XCTAssertEqual(delegate.lastParameterStatus?.name, "client_encoding")
            XCTAssertEqual(delegate.lastParameterStatus?.value, "BIG5")
            
            XCTAssertTrue(connection.isClosed)
        } catch {
            XCTFail(String(describing: error))
        }
    }
}

// EOF
