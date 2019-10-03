//
//  PostgresTimeWithTimeZoneTest.swift
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

/// Tests PostgresTimeWithTimeZone.
class PostgresTimeWithTimeZoneTest: PostgresClientKitTestCase {
    
    func test() {
        
        let plusOneHour = TimeZone(secondsFromGMT: 3600)!
        let minusOneHour = TimeZone(secondsFromGMT: -3600)!
        let plusOneHourThirty = TimeZone(secondsFromGMT: 5400)!
        let minusTenHoursThirty = TimeZone(secondsFromGMT: -37800)!
        
        
        //
        // Test init(hour:minute:second:nanosecond:timeZone) and init(date:in:).
        // This also tests init(_:) for valid strings and canonical-format time zones.
        //
        
        // Time zone that observes daylight savings time should fail.
        XCTAssertNotNil(pacificTimeZone.nextDaylightSavingTimeTransition)
        XCTAssertNil(PostgresTimeWithTimeZone(
            hour: 1, minute: 60, second: 1, nanosecond: 1, timeZone: pacificTimeZone))
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresTimeWithTimeZone(
            hour: 1, minute: 61, second: 1, nanosecond: 1, timeZone: utcTimeZone))
        
        // Valid component values should succeed.
        var time = PostgresTimeWithTimeZone(
            hour: 3, minute: 4, second: 5, nanosecond: 006_000_000, timeZone: utcTimeZone)
        checkTime(time, 3, 4, 5, 006_000_000, utcTimeZone, "03:04:05.006+00:00")
        
        // Round down to nearest millisecond.
        time = PostgresTimeWithTimeZone(
            hour: 13, minute: 14, second: 15, nanosecond: 006_100_000, timeZone: utcTimeZone)
        checkTime(time, 13, 14, 15, 006_000_000, utcTimeZone, "13:14:15.006+00:00")

        // Round up to nearest millisecond.
        time = PostgresTimeWithTimeZone(
            hour: 13, minute: 14, second: 15, nanosecond: 005_900_000, timeZone: utcTimeZone)
        checkTime(time, 13, 14, 15, 006_000_000, utcTimeZone, "13:14:15.006+00:00")

        // Round up to nearest millisecond.
        time = PostgresTimeWithTimeZone(
            hour: 13, minute: 14, second: 15, nanosecond: 999_900_000, timeZone: utcTimeZone)
        checkTime(time, 13, 14, 16, 000_000_000, utcTimeZone, "13:14:16.000+00:00")

        // Test an alternate time zone.
        time = PostgresTimeWithTimeZone(
            hour: 13, minute: 14, second: 15, timeZone: plusOneHour)
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHour, "13:14:15.000+01:00")
        
        // Test an alternate time zone.
        time = PostgresTimeWithTimeZone(
            hour: 13, minute: 14, second: 15, timeZone: minusOneHour)
        checkTime(time, 13, 14, 15, 000_000_000, minusOneHour, "13:14:15.000-01:00")


        //
        // Additional test cases for init(date:in:).
        //

        time = PostgresTimeWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0010), in: utcTimeZone)
        checkTime(time, 0, 0, 0, 001_000_000, utcTimeZone, "00:00:00.001+00:00")

        time = PostgresTimeWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0011), in: plusOneHour)
        checkTime(time, 1, 0, 0, 001_000_000, plusOneHour, "01:00:00.001+01:00")

        time = PostgresTimeWithTimeZone(date: Date(timeIntervalSinceReferenceDate: 0.0009), in: minusOneHour)
        checkTime(time, 23, 0, 0, 001_000_000, minusOneHour, "23:00:00.001-01:00")


        //
        // Additional test cases for init(_:).
        //

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimeWithTimeZone("foo"))

        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimeWithTimeZone("01:61:01.000+00:00"))

        // Valid string representation should succeed.
        time = PostgresTimeWithTimeZone("03:04:05.006+00:00")
        checkTime(time, 3, 4, 5, 006_000_000, utcTimeZone, "03:04:05.006+00:00")

        // Valid string representation should succeed.
        time = PostgresTimeWithTimeZone("03:04:05.06+00:00")
        checkTime(time, 3, 4, 5, 060_000_000, utcTimeZone, "03:04:05.060+00:00")

        // Valid string representation should succeed.
        time = PostgresTimeWithTimeZone("03:04:05.6+00:00")
        checkTime(time, 3, 4, 5, 600_000_000, utcTimeZone, "03:04:05.600+00:00")

        // Fractional seconds are optional.
        time = PostgresTimeWithTimeZone("03:04:05+00:00")
        checkTime(time, 3, 4, 5, 000_000_000, utcTimeZone, "03:04:05.000+00:00")

        // "Z" indicates UTC.
        time = PostgresTimeWithTimeZone("13:14:15.000Z")
        checkTime(time, 13, 14, 15, 000_000_000, utcTimeZone, "13:14:15.000+00:00")

        // "+01:00"
        time = PostgresTimeWithTimeZone("13:14:15.000+01:00")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHour, "13:14:15.000+01:00")
        
        // "-0100"
        time = PostgresTimeWithTimeZone("13:14:15.000-0100")
        checkTime(time, 13, 14, 15, 000_000_000, minusOneHour, "13:14:15.000-01:00")
        
        // "+01"
        time = PostgresTimeWithTimeZone("13:14:15.000+01")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHour, "13:14:15.000+01:00")

        // "-1"
        time = PostgresTimeWithTimeZone("13:14:15.000-1")
        checkTime(time, 13, 14, 15, 000_000_000, minusOneHour, "13:14:15.000-01:00")
        
        // "+01:30"
        time = PostgresTimeWithTimeZone("13:14:15.000+01:30")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHourThirty, "13:14:15.000+01:30")
        
        // "+0130"
        time = PostgresTimeWithTimeZone("13:14:15.000+0130")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHourThirty, "13:14:15.000+01:30")
        
        // "+1:30"
        time = PostgresTimeWithTimeZone("13:14:15.000+1:30")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHourThirty, "13:14:15.000+01:30")
        
        // "+130"
        time = PostgresTimeWithTimeZone("13:14:15.000+130")
        checkTime(time, 13, 14, 15, 000_000_000, plusOneHourThirty, "13:14:15.000+01:30")
        
        // "-10:30"
        time = PostgresTimeWithTimeZone("13:14:15.000-10:30")
        checkTime(time, 13, 14, 15, 000_000_000, minusTenHoursThirty, "13:14:15.000-10:30")
        
        // "-1030"
        time = PostgresTimeWithTimeZone("13:14:15.000-1030")
        checkTime(time, 13, 14, 15, 000_000_000, minusTenHoursThirty, "13:14:15.000-10:30")
    }
    
    func checkTime(
        _ time: PostgresTimeWithTimeZone?,
        _ expectedHour: Int, _ expectedMinute: Int, _ expectedSecond: Int, _ expectedNanosecond: Int,
        _ expectedTimeZone: TimeZone, _ expectedDescription: String) {
        
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
        expectedDateComponents.timeZone = expectedTimeZone
        
        let expectedDate: Date = {
            var dc = expectedDateComponents
            dc.year = 2000; dc.month = 1; dc.day = 1
            return enUsPosixUtcCalendar.date(from: dc)! }()
        
        let expectedPostgresValue = expectedDescription.postgresValue
        
        // Helper function for what's below...
        func checkTime(_ t: PostgresTimeWithTimeZone) {
            
            let tDateComponents = t.dateComponents
            let tDate = t.date
            let tTimeZone = t.timeZone
            let tPostgresValue = t.postgresValue
            let tDescription = t.description
            
            XCTAssertEqual(t, time)
            XCTAssert(isValidDate(tDateComponents))
            XCTAssertApproximatelyEqual(tDateComponents, expectedDateComponents)
            XCTAssertApproximatelyEqual(tDate, expectedDate)
            XCTAssertEqual(tTimeZone, expectedTimeZone)
            XCTAssertEqual(tPostgresValue, expectedPostgresValue)
            XCTAssertEqual(tDescription, expectedDescription)
        }
        
        // Check the supplied time.
        checkTime(time)
        
        // Check init(date:).
        checkTime(PostgresTimeWithTimeZone(date: expectedDate, in: expectedTimeZone)!)
        
        // Check Date.postgresTimeWithTimeZone.
        checkTime(expectedDate.postgresTimeWithTimeZone(in: expectedTimeZone)!)
        
        // Check init(_:).
        checkTime(PostgresTimeWithTimeZone(expectedDescription)!)
    }
}

// EOF
