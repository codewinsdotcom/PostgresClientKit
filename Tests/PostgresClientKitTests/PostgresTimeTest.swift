//
//  PostgresTimeTest.swift
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

/// Tests PostgresTime.
class PostgresTimeTest: PostgresClientKitTestCase {
    
    func test() {
        
        //
        // Test init(hour:minute:second:nanosecond) and init(date:in:).
        // This also tests init(_:) for valid strings.
        //
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTime(hour: 1, minute: 61, second: 1, nanosecond: 1))
        
        // Valid component values should succeed.
        var time = PostgresTime(hour: 3, minute: 4, second: 5, nanosecond: 006_000_000)
        checkTime(time, 3, 4, 5, 006_000_000, "03:04:05.006")

        // Round down to nearest millisecond.
        time = PostgresTime(hour: 13, minute: 14, second: 15, nanosecond: 006_100_000)
        checkTime(time, 13, 14, 15, 006_000_000, "13:14:15.006")

        // Round up to nearest millisecond.
        time = PostgresTime(hour: 13, minute: 14, second: 15, nanosecond: 005_900_000)
        checkTime(time, 13, 14, 15, 006_000_000, "13:14:15.006")

        // Round up to nearest millisecond.
        time = PostgresTime(hour: 13, minute: 14, second: 15, nanosecond: 999_900_000)
        checkTime(time, 13, 14, 16, 000_000_000, "13:14:16.000")


        //
        // Additional test cases for init(date:in:).
        //

        time = PostgresTime(date: Date(timeIntervalSinceReferenceDate: 0.0010), in: utcTimeZone)
        checkTime(time, 0, 0, 0, 001_000_000, "00:00:00.001")

        time = PostgresTime(date: Date(timeIntervalSinceReferenceDate: 0.0011), in: pacificTimeZone)
        checkTime(time, 16, 0, 0, 001_000_000, "16:00:00.001")

        time = PostgresTime(date: Date(timeIntervalSinceReferenceDate: 0.0009), in: pacificTimeZone)
        checkTime(time, 16, 0, 0, 001_000_000, "16:00:00.001")
        
        
        time = PostgresTime(
            date: PostgresTimestampWithTimeZone(year: 2001, month: 1, day: 2,
                                                hour: 3, minute: 4, second: 5, nanosecond: 006_000_000,
                                                timeZone: utcTimeZone)!.date,
            in: utcTimeZone)
        checkTime(time, 3, 4, 5, 006_000_000, "03:04:05.006")


        //
        // Additional test cases for init(_:).
        //

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTime("foo"))

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTime("01:61:01.000"))
        
        // Valid string representation should succeed.
        time = PostgresTime("03:04:05.006")
        checkTime(time, 3, 4, 5, 006_000_000, "03:04:05.006")
        
        // Valid string representation should succeed.
        time = PostgresTime("03:04:05.06")
        checkTime(time, 3, 4, 5, 060_000_000, "03:04:05.060")
        
        // Valid string representation should succeed.
        time = PostgresTime("03:04:05.6")
        checkTime(time, 3, 4, 5, 600_000_000, "03:04:05.600")
        
        // Fractional seconds are optional.
        time = PostgresTime("03:04:05")
        checkTime(time, 3, 4, 5, 000_000_000, "03:04:05.000")
    }
    
    func checkTime(
        _ time: PostgresTime?,
        _ expectedHour: Int, _ expectedMinute: Int, _ expectedSecond: Int, _ expectedNanosecond: Int,
        _ expectedDescription: String) {
        
        if time == nil {
            XCTAssertNotNil(time)
            return
        }
        
        let time = time!
        
        var expectedDateComponents = DateComponents()
        expectedDateComponents.hour = expectedHour
        expectedDateComponents.minute = expectedMinute
        expectedDateComponents.second = expectedSecond
        expectedDateComponents.nanosecond = expectedNanosecond
        
        let expectedUtcDate: Date = {
            var dc = expectedDateComponents
            dc.year = 2000; dc.month = 1; dc.day = 1
            dc.timeZone = utcTimeZone
            return enUsPosixUtcCalendar.date(from: dc)! }()
        
        let expectedPacificDate: Date = {
            var dc = expectedDateComponents
            dc.year = 2000; dc.month = 1; dc.day = 1
            dc.timeZone = pacificTimeZone
            return enUsPosixUtcCalendar.date(from: dc)! }()
        
        let expectedPostgresValue = expectedDescription.postgresValue
        
        // Helper function for what's below...
        func checkTime(_ t: PostgresTime) {
            
            let tDateComponents = t.dateComponents
            let tUtcDate = t.date(in: utcTimeZone)
            let tPacificDate = t.date(in: pacificTimeZone)
            let tPostgresValue = t.postgresValue
            let tDescription = t.description
            
            XCTAssertEqual(t, time)
            XCTAssert(isValidDate(tDateComponents))
            XCTAssertApproximatelyEqual(tDateComponents, expectedDateComponents)
            XCTAssertApproximatelyEqual(tUtcDate, expectedUtcDate)
            XCTAssertApproximatelyEqual(tPacificDate, expectedPacificDate)
            XCTAssertEqual(tPostgresValue, expectedPostgresValue)
            XCTAssertEqual(tDescription, expectedDescription)
        }
        
        // Check the supplied timestamp.
        checkTime(time)
        
        // Check init(date:in:).
        checkTime(PostgresTime(date: expectedUtcDate, in: utcTimeZone))
        checkTime(PostgresTime(date: expectedPacificDate, in: pacificTimeZone))
        
        // Check Date.postgresTime(in:).
        checkTime(expectedUtcDate.postgresTime(in: utcTimeZone))
        checkTime(expectedPacificDate.postgresTime(in: pacificTimeZone))
        
        // Check init(_:).
        checkTime(PostgresTime(expectedDescription)!)
    }
}

// EOF
