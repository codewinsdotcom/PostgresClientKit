//
//  PostgresTimestampTest.swift
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

/// Tests PostgresTimestamp.
class PostgresTimestampTest: PostgresClientKitTestCase {
    
    func test() {
        
        //
        // Test init(year:month:day:hour:minute:second:nanosecond) and init(date:in:).
        // This also tests init(_:) for valid strings.
        //
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTimestamp(
            year: 2019, month: 0, day: 1,
            hour: 1, minute: 1, second: 1, nanosecond: 1))
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTimestamp(
            year: 2019, month: 2, day: 29,
            hour: 1, minute: 1, second: 1))
        
        // Valid component values should succeed.
        var timestamp = PostgresTimestamp(
            year: 2019, month: 1, day: 2,
            hour: 3, minute: 4, second: 5, nanosecond: 006_000_000)
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 006_000_000, "2019-01-02 03:04:05.006")

        // Round down to nearest millisecond.
        timestamp = PostgresTimestamp(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 006_100_000)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 006_000_000, "2019-01-02 13:14:15.006")

        // Round up to nearest millisecond.
        timestamp = PostgresTimestamp(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 005_900_000)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 006_000_000, "2019-01-02 13:14:15.006")

        // Round up to nearest millisecond.
        timestamp = PostgresTimestamp(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 999_900_000)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 16, 000_000_000, "2019-01-02 13:14:16.000")


        //
        // Additional test cases for init(date:in:).
        //

        timestamp = PostgresTimestamp(date: Date(timeIntervalSinceReferenceDate: 0.0010), in: utcTimeZone)
        checkTimestamp(timestamp, 2001, 1, 1, 0, 0, 0, 001_000_000, "2001-01-01 00:00:00.001")

        timestamp = PostgresTimestamp(date: Date(timeIntervalSinceReferenceDate: 0.0011), in: pacificTimeZone)
        checkTimestamp(timestamp, 2000, 12, 31, 16, 0, 0, 001_000_000, "2000-12-31 16:00:00.001")

        timestamp = PostgresTimestamp(date: Date(timeIntervalSinceReferenceDate: 0.0009), in: pacificTimeZone)
        checkTimestamp(timestamp, 2000, 12, 31, 16, 0, 0, 001_000_000, "2000-12-31 16:00:00.001")


        //
        // Additional test cases for init(_:).
        //

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestamp("foo"))

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestamp("2019-00-01 01:01:01.000"))

        // Valid string representation should succeed.
        timestamp = PostgresTimestamp("2019-01-02 03:04:05.006")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 006_000_000, "2019-01-02 03:04:05.006")
        
        // Valid string representation should succeed.
        timestamp = PostgresTimestamp("2019-01-02 03:04:05.06")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 060_000_000, "2019-01-02 03:04:05.060")
        
        // Valid string representation should succeed.
        timestamp = PostgresTimestamp("2019-01-02 03:04:05.6")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 600_000_000, "2019-01-02 03:04:05.600")
        
        // Fractional seconds are optional.
        timestamp = PostgresTimestamp("2019-01-02 03:04:05")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 000_000_000, "2019-01-02 03:04:05.000")
    }
    
    func checkTimestamp(
        _ timestamp: PostgresTimestamp?,
        _ expectedYear: Int, _ expectedMonth: Int, _ expectedDay: Int,
        _ expectedHour: Int, _ expectedMinute: Int, _ expectedSecond: Int, _ expectedNanosecond: Int,
        _ expectedDescription: String) {
        
        if timestamp == nil {
            XCTAssertNotNil(timestamp)
            return
        }
        
        let timestamp = timestamp!
        
        var expectedDateComponents = DateComponents()
        expectedDateComponents.year = expectedYear
        expectedDateComponents.month = expectedMonth
        expectedDateComponents.day = expectedDay
        expectedDateComponents.hour = expectedHour
        expectedDateComponents.minute = expectedMinute
        expectedDateComponents.second = expectedSecond
        expectedDateComponents.nanosecond = expectedNanosecond
        
        let expectedUtcDate: Date = {
            var dc = expectedDateComponents
            dc.timeZone = utcTimeZone
            return enUsPosixUtcCalendar.date(from: dc)! }()
        
        let expectedPacificDate: Date = {
            var dc = expectedDateComponents
            dc.timeZone = pacificTimeZone
            return enUsPosixUtcCalendar.date(from: dc)! }()
        
        let expectedPostgresValue = expectedDescription.postgresValue
        
        // Helper function for what's below...
        func checkTimestamp(_ ts: PostgresTimestamp) {
            
            let tsDateComponents = ts.dateComponents
            let tsUtcDate = ts.date(in: utcTimeZone)
            let tsPacificDate = ts.date(in: pacificTimeZone)
            let tsPostgresValue = ts.postgresValue
            let tsDescription = ts.description
            
            XCTAssertEqual(ts, timestamp)
            XCTAssert(isValidDate(tsDateComponents))
            XCTAssertApproximatelyEqual(tsDateComponents, expectedDateComponents)
            XCTAssertApproximatelyEqual(tsUtcDate, expectedUtcDate)
            XCTAssertApproximatelyEqual(tsPacificDate, expectedPacificDate)
            XCTAssertEqual(tsPostgresValue, expectedPostgresValue)
            XCTAssertEqual(tsDescription, expectedDescription)
        }
        
        // Check the supplied timestamp.
        checkTimestamp(timestamp)
        
        // Check init(date:in:).
        checkTimestamp(PostgresTimestamp(date: expectedUtcDate, in: utcTimeZone))
        checkTimestamp(PostgresTimestamp(date: expectedPacificDate, in: pacificTimeZone))

        // Check Date.postgresTimestamp(in:).
        checkTimestamp(expectedUtcDate.postgresTimestamp(in: utcTimeZone))
        checkTimestamp(expectedPacificDate.postgresTimestamp(in: pacificTimeZone))

        // Check init(_:).
        checkTimestamp(PostgresTimestamp(expectedDescription)!)
    }
}

// EOF
