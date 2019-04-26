//
//  StatementTest.swift
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

/// Tests Statement.
class StatementTest: PostgresClientKitTestCase {
    
    func testPrepareStatement() {
        
        do {
            try createWeatherTable()
            
            // Success case
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                _ = try connection.prepareStatement(text: text)
            }
            
            // Throws if invalid SQL text
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "invalid-text"
                let operation = { try connection.prepareStatement(text: text) }
                
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.sqlError = error else {
                        return XCTFail(String(describing: error))
                    }
                }
            }
            
            // Throws if connection closed
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                connection.close()
                let text = "SELECT * FROM weather"
                let operation = { try connection.prepareStatement(text: text) }
                
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.connectionClosed = error else {
                        return XCTFail(String(describing: error))
                    }
                }
            }
            
            // Closes an open, undrained cursor
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement1 = try connection.prepareStatement(text: text)
                let cursor1 = try statement1.execute()
                XCTAssertFalse(statement1.isClosed)
                XCTAssertFalse(cursor1.isClosed)
                let statement2 = try connection.prepareStatement(text: text)
                XCTAssertFalse(statement1.isClosed)
                XCTAssertTrue(cursor1.isClosed)
                XCTAssertFalse(statement2.isClosed)
            }
            
            // Closes an open, drained cursor
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement1 = try connection.prepareStatement(text: text)
                let cursor1 = try statement1.execute()
                while cursor1.next() != nil { }
                XCTAssertFalse(statement1.isClosed)
                XCTAssertFalse(cursor1.isClosed)
                XCTAssertNil(cursor1.next()) // "drained"
                let statement2 = try connection.prepareStatement(text: text)
                XCTAssertFalse(statement1.isClosed)
                XCTAssertTrue(cursor1.isClosed)
                XCTAssertFalse(statement2.isClosed)
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    func testStatementLifecycle() {
        do {
            try createWeatherTable()
            
            let connection = try Connection(configuration: terryConnectionConfiguration())
            let text = "SELECT * FROM weather"
            let statement1 = try connection.prepareStatement(text: text)
            let statement2 = try connection.prepareStatement(text: text)
            
            // Each statement has a unique id
            XCTAssertNotEqual(statement1.id, statement2.id)
            
            // The description property is the id value
            XCTAssertEqual(statement1.id, statement1.description)
            
            // The statement belongs to the connection that created it
            XCTAssertTrue(statement1.connection === connection)
            
            // The text property is the SQL text
            XCTAssertEqual(statement1.text, text)
            
            // Statements are initially open
            XCTAssertFalse(statement1.isClosed)
            XCTAssertFalse(statement2.isClosed)
            
            // Statements can be independently closed
            statement1.close()
            XCTAssertTrue(statement1.isClosed)
            XCTAssertFalse(statement2.isClosed)
            
            // close() is idempotent
            statement1.close()
            XCTAssertTrue(statement1.isClosed)
            XCTAssertFalse(statement2.isClosed)
            
            // Closing a connection closes its statements
            connection.close()
            XCTAssertTrue(statement1.isClosed)
            XCTAssertTrue(statement2.isClosed)
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    func testExecuteStatement() {
        do {
            try createWeatherTable()
            
            // Success case without parameters
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement = try connection.prepareStatement(text: text)
                _ = try statement.execute()
            }
            
            // Success case with with parameters
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather WHERE date = $1"
                let statement = try connection.prepareStatement(text: text)
                _ = try statement.execute(parameterValues: [ "1994-12-29" ])
            }
            
            // Throws if parameters invalid
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather WHERE date = $1"
                let statement = try connection.prepareStatement(text: text)
                let operation = { try statement.execute(parameterValues: [ "invalid-date" ]) }
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.sqlError = error else {
                        return XCTFail(String(describing: error))
                    }
                }
            }
            
            // Throws if connection closed
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement = try connection.prepareStatement(text: text)
                connection.close()
                let operation = { try statement.execute() }
                
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.connectionClosed = error else {
                        return XCTFail(String(describing: error))
                    }
                }
            }
            
            // Throws if statement closed
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement = try connection.prepareStatement(text: text)
                statement.close()
                let operation = { try statement.execute() }
                
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.statementClosed = error else {
                        return XCTFail(String(describing: error))
                    }
                }
            }
            
            // Closes an open, undrained cursor
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement1 = try connection.prepareStatement(text: text)
                let statement2 = try connection.prepareStatement(text: text)
                let cursor1 = try statement1.execute()
                XCTAssertFalse(statement1.isClosed)
                XCTAssertFalse(cursor1.isClosed)
                XCTAssertFalse(statement2.isClosed)
                let cursor2 = try statement2.execute()
                XCTAssertFalse(statement1.isClosed)
                XCTAssertTrue(cursor1.isClosed)
                XCTAssertFalse(statement2.isClosed)
                XCTAssertFalse(cursor2.isClosed)
            }
            
            // Closes an open, drained cursor
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT * FROM weather"
                let statement1 = try connection.prepareStatement(text: text)
                let statement2 = try connection.prepareStatement(text: text)
                let cursor1 = try statement1.execute()
                while cursor1.next() != nil { }
                XCTAssertFalse(statement1.isClosed)
                XCTAssertFalse(cursor1.isClosed)
                XCTAssertNil(cursor1.next()) // "drained"
                XCTAssertFalse(statement2.isClosed)
                let cursor2 = try statement2.execute()
                XCTAssertFalse(statement1.isClosed)
                XCTAssertTrue(cursor1.isClosed)
                XCTAssertFalse(statement2.isClosed)
                XCTAssertFalse(cursor2.isClosed)
            }
            
            // Repeated execution of same statement
            do {
                let connection = try Connection(configuration: terryConnectionConfiguration())
                let text = "SELECT COUNT(*) FROM weather WHERE date = $1"
                let statement = try connection.prepareStatement(text: text)
                
                let cursor1 = try statement.execute(parameterValues: [ "1994-11-27" ])
                XCTAssertFalse(statement.isClosed)
                XCTAssertFalse(cursor1.isClosed)
                var columns = try cursor1.next()!.get().columns
                XCTAssertEqual(try columns[0].int(), 1)
                XCTAssertNil(cursor1.next())
                XCTAssertFalse(cursor1.isClosed) // drained, but not closed
                
                let cursor2 = try statement.execute(parameterValues: [ "1994-11-29" ])
                XCTAssertFalse(statement.isClosed)
                XCTAssertTrue(cursor1.isClosed)
                XCTAssertFalse(cursor2.isClosed)
                columns = try cursor2.next()!.get().columns
                XCTAssertEqual(try columns[0].int(), 2)
                XCTAssertNil(cursor2.next())
                XCTAssertFalse(cursor2.isClosed) // drained, but not closed
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }
}

// EOF
