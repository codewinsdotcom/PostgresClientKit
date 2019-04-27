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
            
            // Each connection has a unique id
            XCTAssertNotEqual(connection1.id, connection2.id)
            
            // The description property is the id value
            XCTAssertEqual(connection1.id, connection1.description)
            
            // No delegate by default
            XCTAssertNil(connection1.delegate)
            
            // Connections are initially open
            XCTAssertFalse(connection1.isClosed)
            XCTAssertFalse(connection2.isClosed)
            
            // Connections can be independently closed
            connection1.close()
            XCTAssertTrue(connection1.isClosed)
            XCTAssertFalse(connection2.isClosed)
            
            // close() is idempotent
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
    
    func testTransactions() {
        
        do {
            func countWeatherRows(_ connection: Connection) throws -> Int {
                
                let text = "SELECT COUNT(*) FROM weather"
                let statement = try connection.prepareStatement(text: text)
                let cursor = try statement.execute()
                let firstRow = try cursor.next()!.get()
                let count = try firstRow.columns[0].int()
                
                return count
            }
            
            func resetTestData(_ connection: Connection) throws {
                
                try createWeatherTable()
                
                let statement = try connection.prepareStatement(text: """
                    CREATE OR REPLACE FUNCTION testWeather(deleteCity VARCHAR, selectDate VARCHAR)
                        RETURNS SETOF weather
                        LANGUAGE SQL
                    AS $$
                        DELETE FROM weather WHERE city = deleteCity;
                        SELECT * FROM weather WHERE date = CAST(selectDate AS DATE);
                    $$;
                    """)
                
                try statement.execute()
            }
            
            let performer = try Connection(configuration: terryConnectionConfiguration())
            let observer = try Connection(configuration: terryConnectionConfiguration())
            
            
            //
            // Implicit transactions
            //
            
            // If there are no rows in the result, the transaction is implicitly committed upon
            // successful completion of Statement.execute.
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                let text = "DELETE FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertEqual(try countWeatherRows(observer), 0)
                cursor.close()
                XCTAssertEqual(try countWeatherRows(observer), 0)
            }
            
            // If there are no rows in the result, the transaction is implicitly committed upon
            // successful completion of Statement.execute
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                let text = "SELECT * FROM testWeather($1, $2)"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute(
                    parameterValues: [ "Hayward", "2000-01-01" ]) // delete 1 row, return 0 rows
                XCTAssertEqual(try countWeatherRows(observer), 2)
                for row in cursor { _ = try row.get() } // retrieve all rows
                XCTAssertEqual(try countWeatherRows(observer), 2)
                cursor.close()
                XCTAssertEqual(try countWeatherRows(observer), 2)
            }
            
            // If there are one or more rows in the result, the transaction is implicitly committed
            // after the final row has been retrieved
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                let text = "SELECT * FROM testWeather($1, $2)"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute(
                    parameterValues: [ "Hayward", "1994-11-29" ]) // delete 1 row, return 1 row
                XCTAssertEqual(try countWeatherRows(observer), 3)
                for row in cursor { _ = try row.get() } // retrieve all rows
                XCTAssertEqual(try countWeatherRows(observer), 2)
                cursor.close()
                XCTAssertEqual(try countWeatherRows(observer), 2)
            }
            
            // If there are one or more rows in the result, the transaction is also implicitly
            // committed when the cursor is closed
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                let text = "SELECT * FROM testWeather($1, $2)"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute(
                    parameterValues: [ "Hayward", "1994-11-29" ]) // delete 1 row, return 1 row
                XCTAssertEqual(try countWeatherRows(observer), 3)
                cursor.close()
                XCTAssertEqual(try countWeatherRows(observer), 2)
            }

            // If the statement fails, it is implicitly rolled back
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                let text = "SELECT * FROM testWeather($1, $2)"
                let statement = try performer.prepareStatement(text: text)
                let operation = { try statement.execute(
                    parameterValues: [ "Hayward", "invalid-date" ]) } // delete 1 row, then fail
                
                XCTAssertThrowsError(try operation()) { error in
                    guard case PostgresError.sqlError = error else {
                        return XCTFail(String(describing: error))
                    }
                }
                
                XCTAssertEqual(try countWeatherRows(observer), 3)
            }
            
            
            //
            // Explicit transactions
            //
            
            // beginTransaction() closes any open cursor
            do {
                let text = "SELECT * FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertFalse(cursor.isClosed)
                try performer.beginTransaction()
                XCTAssertTrue(cursor.isClosed)
                try performer.rollbackTransaction()
            }
            
            // commitTransaction() closes any open cursor
            do {
                let text = "SELECT * FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertFalse(cursor.isClosed)
                try performer.commitTransaction()
                XCTAssertTrue(cursor.isClosed)
            }
            
            // rollbackTransaction() closes any open cursor
            do {
                let text = "SELECT * FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertFalse(cursor.isClosed)
                try performer.rollbackTransaction()
                XCTAssertTrue(cursor.isClosed)
            }
            
            // beginTransaction() + commitTransaction()
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(performer), 3)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                try performer.beginTransaction()
                let text = "DELETE FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                cursor.close()
                statement.close()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                try performer.commitTransaction()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 0)
            }
            
            // beginTransaction() + rollbackTransaction()
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(performer), 3)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                try performer.beginTransaction()
                let text = "DELETE FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                cursor.close()
                statement.close()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                try performer.rollbackTransaction()
                XCTAssertEqual(try countWeatherRows(performer), 3)
                XCTAssertEqual(try countWeatherRows(observer), 3)
            }
            
            // Closing a connection rolls back any explicit transaction
            do {
                try resetTestData(performer)
                XCTAssertEqual(try countWeatherRows(performer), 3)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                try performer.beginTransaction()
                let text = "DELETE FROM weather"
                let statement = try performer.prepareStatement(text: text)
                let cursor = try statement.execute()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                cursor.close()
                statement.close()
                XCTAssertEqual(try countWeatherRows(performer), 0)
                XCTAssertEqual(try countWeatherRows(observer), 3)
                performer.close()
                XCTAssertEqual(try countWeatherRows(observer), 3)
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    func testErrorRecovery() {
        do {
            let connection = try Connection(configuration: terryConnectionConfiguration())
            var text = "invalid-text"

            XCTAssertThrowsError(try connection.prepareStatement(text: text)) { error in
                guard case PostgresError.sqlError = error else {
                    return XCTFail(String(describing: error))
                }
            }
            
            XCTAssertFalse(connection.isClosed)
            
            text = "SELECT $1"
            let statement = try connection.prepareStatement(text: text)
            
            XCTAssertThrowsError(try statement.execute()) { error in
                guard case PostgresError.sqlError = error else {
                    return XCTFail(String(describing: error))
                }
            }
            
            XCTAssertFalse(connection.isClosed)

            let cursor = try statement.execute(parameterValues: [ 123 ])
            let row = cursor.next()
            XCTAssertNotNil(row)
            XCTAssertEqual(try row?.get().columns[0].int(), 123)
            
            XCTAssertFalse(connection.isClosed)

            connection.close()
            XCTAssertTrue(connection.isClosed)
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    // TODO: statement test (SELECT, INSERT, UPDATE, DELETE)
    // TODO: data type test
}

// EOF
