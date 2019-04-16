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
class PostgresTimestampWithTimeZoneTest: XCTestCase {
    
    let utcTimeZone = TimeZone(secondsFromGMT: 0)!
    
    let pacificTimeZone = TimeZone.init(identifier: "America/Los_Angeles")!
    
    lazy var utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = utcTimeZone
        return calendar
    }()
    
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
            hour: 3, minute: 4, second: 5, nanosecond: 6000000,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 6000000, "2019-01-02 03:04:05.006+00:00")
        
        // Round down to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 6000001,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 6000000, "2019-01-02 13:14:15.006+00:00")
        
        // Round up to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 5999999,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 15, 6000000, "2019-01-02 13:14:15.006+00:00")
        
        // Round up to nearest millisecond.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15, nanosecond: 999999999,
            timeZone: utcTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 13, 14, 16, 0, "2019-01-02 13:14:16.000+00:00")
        
        // Normalize from PST to UTC.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 1, day: 2,
            hour: 13, minute: 14, second: 15,
            timeZone: pacificTimeZone)
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 0, "2019-01-02 21:14:15.000+00:00")
        
        // Normalize from PDT to UTC.
        timestamp = PostgresTimestampWithTimeZone(
            year: 2019, month: 7, day: 2,
            hour: 13, minute: 14, second: 15,
            timeZone: pacificTimeZone)
        checkTimestamp(timestamp, 2019, 7, 2, 20, 14, 15, 0, "2019-07-02 20:14:15.000+00:00")
        
        
        //
        // Additional test cases for init(_:).
        //
        
        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone("foo"))
        
        // Invalid string representation should fail.
        XCTAssertNil(PostgresTimestampWithTimeZone("2019-00-01 01:01:01.000+00:00"))
        
        // Valid string representation should succeed.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 03:04:05.006+00:00")
        checkTimestamp(timestamp, 2019, 1, 2, 3, 4, 5, 6000000, "2019-01-02 03:04:05.006+00:00")
        
        // Normalize "-08:00" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08:00")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 0, "2019-01-02 21:14:15.000+00:00")
        
        // Normalize "-0800" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-0800")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 0, "2019-01-02 21:14:15.000+00:00")
        
        // Normalize "-08" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 14, 15, 0, "2019-01-02 21:14:15.000+00:00")
        
        // Normalize "-08:30" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-08:30")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 44, 15, 0, "2019-01-02 21:44:15.000+00:00")
        
        // Normalize "-0830" to UTC.
        timestamp = PostgresTimestampWithTimeZone("2019-01-02 13:14:15.000-0830")
        checkTimestamp(timestamp, 2019, 1, 2, 21, 44, 15, 0, "2019-01-02 21:44:15.000+00:00")
    }

    func checkTimestamp(
        _ timestamp: PostgresTimestampWithTimeZone?,
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int,
        _ postgresValue: PostgresValueConvertible) {
        
        XCTAssertNotNil(timestamp)
        
        // Check the dateComponents property.
        let dateComponents = timestamp!.dateComponents
        XCTAssert(dateComponents.isValidDate)
        XCTAssertEqual(dateComponents.calendar, utcCalendar)
        XCTAssertEqual(dateComponents.timeZone, utcTimeZone)
        XCTAssertEqual(dateComponents.era, nil)
        XCTAssertEqual(dateComponents.year, year)
        XCTAssertEqual(dateComponents.yearForWeekOfYear, nil)
        XCTAssertEqual(dateComponents.quarter, nil)
        XCTAssertEqual(dateComponents.month, month)
        XCTAssertEqual(dateComponents.weekOfMonth, nil)
        XCTAssertEqual(dateComponents.weekOfYear, nil)
        XCTAssertEqual(dateComponents.weekday, nil)
        XCTAssertEqual(dateComponents.weekdayOrdinal, nil)
        XCTAssertEqual(dateComponents.day, day)
        XCTAssertEqual(dateComponents.hour, hour)
        XCTAssertEqual(dateComponents.minute, minute)
        XCTAssertEqual(dateComponents.second, second)
        XCTAssertNotNil(dateComponents.nanosecond)
        
        let dateComponentsMillisecond = (Double(dateComponents.nanosecond!) / 1000000).rounded()
        let expectedMilliscond = (Double(nanosecond) / 1000000).rounded()
        XCTAssertEqual(dateComponentsMillisecond, expectedMilliscond)
        
        // Check the date property by comparing it against a date created from the already-validated
        // dateComponents property.
        XCTAssertEqual(timestamp!.date, utcCalendar.date(from: dateComponents))
        
        // Check the postgresValue property.
        XCTAssertEqual(timestamp!.postgresValue, postgresValue.postgresValue)
        
        // Check the description property.
        XCTAssertEqual(timestamp!.description, postgresValue.postgresValue.rawValue)
        
        // Check init(date:) using the already-validated date property.
        var timestamp2 = PostgresTimestampWithTimeZone(date: timestamp!.date)
        XCTAssertEqual(timestamp2.dateComponents, timestamp!.dateComponents)
        XCTAssertEqual(timestamp2.date, timestamp!.date)
        XCTAssertEqual(timestamp2.postgresValue, timestamp!.postgresValue)
        XCTAssertEqual(timestamp2.description, timestamp!.description)
        
        // Check Date.postgresTimestampWithTimeZone the same way.
        timestamp2 = timestamp!.date.postgresTimestampWithTimeZone
        XCTAssertEqual(timestamp2.dateComponents, timestamp!.dateComponents)
        XCTAssertEqual(timestamp2.date, timestamp!.date)
        XCTAssertEqual(timestamp2.postgresValue, timestamp!.postgresValue)
        XCTAssertEqual(timestamp2.description, timestamp!.description)

        // Check init(_:).
        timestamp2 = PostgresTimestampWithTimeZone(timestamp!.description)!
        XCTAssertEqual(timestamp2.dateComponents, timestamp!.dateComponents)
        XCTAssertEqual(timestamp2.date, timestamp!.date)
        XCTAssertEqual(timestamp2.postgresValue, timestamp!.postgresValue)
        XCTAssertEqual(timestamp2.description, timestamp!.description)
    }
}

// EOF
