//
//  CursorTest.swift
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

/// Tests Cursor.
class CursorTest: PostgresClientKitTestCase {
    
    func testCursorLifecycle() {
        do {
            try createWeatherTable()
            
            let connection = try Connection(configuration: terryConnectionConfiguration())
            let text = "SELECT * FROM weather"
            let statement = try connection.prepareStatement(text: text)
            
            // Cursors are originally open
            let cursor1 = try statement.execute()
            XCTAssertFalse(cursor1.isClosed)
            
            // There is no more than one open cursor per connection
            let cursor2 = try statement.execute()
            XCTAssertTrue(cursor1.isClosed)
            XCTAssertFalse(cursor2.isClosed)
            
            // Each cursor has a unique id
            XCTAssertNotEqual(cursor1.id, cursor2.id)
            
            // The description property is the id value
            XCTAssertEqual(cursor2.id, cursor2.description)
            
            // The cursor belongs to the statement that created it
            XCTAssertTrue(cursor2.statement === statement)
            
            // The rowCount property is not set until the last row has been retrieved
            XCTAssertNil(cursor2.rowCount)
            
            // next() returns nil if there are no more rows
            var rowCount = 0
            while true {
                guard let row = cursor2.next() else {
                    break
                }
                
                _ = try row.get()
                rowCount += 1
                XCTAssertNil(cursor2.rowCount)
            }
            
            // The rowCount property is set after the last row has been retrieved
            XCTAssertEqual(cursor2.rowCount, 3)
            
            // The rowCount property equals the number of rows returned
            XCTAssertEqual(cursor2.rowCount, rowCount)
            
            // After the last row has been retrieved, the cursor is "drained" but still open
            XCTAssertTrue(cursor1.isClosed)
            XCTAssertFalse(cursor2.isClosed)
            
            // Cursors can be independently closed
            cursor1.close()
            XCTAssertTrue(cursor1.isClosed)
            XCTAssertFalse(cursor2.isClosed)
            
            cursor2.close()
            XCTAssertTrue(cursor1.isClosed)
            XCTAssertTrue(cursor2.isClosed)
            
            // close() is idempotent
            cursor1.close()
            cursor2.close()
            XCTAssertTrue(cursor1.isClosed)
            XCTAssertTrue(cursor2.isClosed)
            
            // next() throws if cursor closed
            XCTAssertThrowsError(try cursor2.next()?.get()) { error in
                guard case PostgresError.cursorClosed = error else {
                    return XCTFail(String(describing: error))
                }
            }
            
            // Closing a statement closes any open cursor for the connection
            let cursor3 = try statement.execute()
            XCTAssertFalse(cursor3.isClosed)
            statement.close()
            XCTAssertTrue(cursor3.isClosed)
            
            // next() throws if statement closed
            XCTAssertThrowsError(try cursor3.next()?.get()) { error in
                guard case PostgresError.statementClosed = error else {
                    return XCTFail(String(describing: error))
                }
            }

            // Closing a connection closes any open cursor for that connection
            let cursor4 = try connection.prepareStatement(text: text).execute()
            XCTAssertFalse(cursor4.isClosed)
            connection.close()
            XCTAssertTrue(cursor4.isClosed)
            
            // next() throws if connection closed
            XCTAssertThrowsError(try cursor4.next()?.get()) { error in
                guard case PostgresError.connectionClosed = error else {
                    return XCTFail(String(describing: error))
                }
            }
        } catch {
            XCTFail(String(describing: error))
        }
    }
}

// EOF
