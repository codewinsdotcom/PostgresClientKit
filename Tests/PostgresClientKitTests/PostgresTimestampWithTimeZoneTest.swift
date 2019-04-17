//
//  PostgresTimestampWithTimeZoneTest.swift
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

/// Tests PostgresTimestampWithTimeZone.
class PostgresTimestampWithTimeZoneTest: PostgresClientKitTestCase {
    
    func test() {
        
        //
        // Test init(year:month:day:hour:minute:second:nanosecond:timeZone) and init(date:).
        // This also tests init(_:) for valid strings with timeZone "+00:00".
        //
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone(
            year: 2019, month: 0, day: 1,
            hour: 1, minute: 1, second: 1, nanosecond: 1, timeZone: utcTimeZone))
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone(
            year: 2019, month: 2, day: 29,
            hour: 1, minute: 1, second: 1, timeZone: utcTimeZone))
        
        // Valid component values should succeed.
        var timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 3, minute: 4, second: 5, nanosecond: 006_000_000,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 006_000_000, "2019-01-02 03:04:05.006+00:00")
        
        // Round down to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 006_100_000,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 006_000_000, "2019-01-02 13:14:15.006+00:00")

        // Round up to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 005_900_000,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 006_000_000, "2019-01-02 13:14:15.006+00:00")

        // Round up to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 999_900_000,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 16, 000_000_000, "2019-01-02 13:14:16.000+00:00")

        // Normalize from PST to UTC.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15,
            timeZone: pacificTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 000_000_000, "2019-01-02 21:14:15.000+00:00")

        // Normalize from PDT to UTC.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 7, day: 2,
            hour: 13, minute: 14, second: 15,
            timeZone: pacificTimeZone)
        checkTimestamp(timestamp, 2019, 7, 2, 20, 14, 15, 000_000_000, "2019-07-02 20:14:15.000+00:00")
        
        
        //
        // Additional test cases for init(date:).
        //
        
        timestamp = PostgresTimestampWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0010))
        checkTimestamp(timestamp, 2001, 1, 1, 0, 0, 0, 001_000_000, "2001-01-01 00:00:00.001+00:00")
        
        timestamp = PostgresTimestampWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0011))
        checkTimestamp(timestamp, 2001, 1, 1, 0, 0, 0, 001_000_000, "2001-01-01 00:00:00.001+00:00")
        
        timestamp = PostgresTimestampWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0009))
        checkTimestamp(timestamp, 2001, 1, 1, 0, 0, 0, 001_000_000, "2001-01-01 00:00:00.001+00:00")
        

        //
        // Additional test cases for init(_:).
        //

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone("foo"))

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone("2019-00-01 01:01:01.000+00:00"))

        // Valid string representation should succeed.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 03:04:05.006+00:00")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 006_000_000, "2019-01-02 03:04:05.006+00:00")

        // "Z" indicates UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000Z")
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 000_000_000, "2019-01-02 13:14:15.000+00:00")

        // Normalize "-08:00" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08:00")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 000_000_000, "2019-01-02 21:14:15.000+00:00")

        // Normalize "-0800" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-0800")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 000_000_000, "2019-01-02 21:14:15.000+00:00")

        // Normalize "-08" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 000_000_000, "2019-01-02 21:14:15.000+00:00")

        // Normalize "-08:30" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08:30")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 44, 15, 000_000_000, "2019-01-02 21:44:15.000+00:00")

        // Normalize "-0830" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-0830")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 44, 15, 000_000_000, "2019-01-02 21:44:15.000+00:00")
    }

    func checkTimestamp(
        _ timestamp: PostgresTimestampWithTimeZone?,
        _ expectedYear: Int, _ expectedMonth: Int, _ expectedDay: Int,
        _ expectedHour: Int, _ expectedMinute: Int, _ expectedSecond: Int, _ expectedNanosecond: Int,
        _ expectedDescription: String) {
        
        if timestamp == nil {
            XCTAssertNotNil(timestamp)
            return
        }
        
        let timestamp = timestamp!

        var expectedDateComponents = DateComponents()
        expectedDateComponents.calendar = utcCalendar
        expectedDateComponents.year = expectedYear
        expectedDateComponents.month = expectedMonth
        expectedDateComponents.day = expectedDay
        expectedDateComponents.hour = expectedHour
        expectedDateComponents.minute = expectedMinute
        expectedDateComponents.second = expectedSecond
        expectedDateComponents.nanosecond = expectedNanosecond
        expectedDateComponents.timeZone = utcTimeZone

        let expectedDate = utcCalendar.date(from: expectedDateComponents)!
        let expectedPostgresValue = expectedDescription.postgresValue

        // Helper function for what's below...
        func checkTimestamp(_ ts: PostgresTimestampWithTimeZone) {
            
            let tsDateComponents = ts.dateComponents
            let tsDate = ts.date
            let tsPostgresValue = ts.postgresValue
            let tsDescription = ts.description
            
            XCTAssert(tsDateComponents.isValidDate)
            XCTAssertApproximatelyEqual(tsDateComponents, expectedDateComponents)
            XCTAssertApproximatelyEqual(tsDate, expectedDate)
            XCTAssertEqual(tsPostgresValue, expectedPostgresValue)
            XCTAssertEqual(tsDescription, expectedDescription)
        }
        
        // Check the supplied timestamp.
        checkTimestamp(timestamp)
        
        // Check init(date:).
        checkTimestamp(PostgresTimestampWithTimeZone(date: expectedDate))

        // Check Date.postgresTimestampWithTimeZone.
        checkTimestamp(expectedDate.postgresTimestampWithTimeZone)

        // Check init(_:).
        checkTimestamp(PostgresTimestampWithTimeZone(expectedDescription)!)
    }
}

// EOF
