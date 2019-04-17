//
//  PostgresDateTest.swift
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

/// Tests PostgresDate.
class PostgresDateTest: PostgresClientKitTestCase {
    
    func test() {
        
        //
        // Test init(year:month:day) and init(date:in:).
        // This also tests init(_:) for valid strings.
        //
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresDate(year: 2019, month: 0, day: 1))
        
        // Invalid component values should fail.
        XCTAssertNil(PostgresDate(year: 2019, month: 2, day: 29))
        
        // Valid component values should succeed.
        var postgresDate = PostgresDate(year: 2019, month: 1, day: 2)
        checkPostgresDate(postgresDate, 2019, 1, 2, "2019-01-02")


        //
        // Additional test cases for init(date:in:).
        //

        postgresDate = PostgresDate(date: Date(timeIntervalSinceReferenceDate: 3661.1), in: utcTimeZone)
        checkPostgresDate(postgresDate, 2001, 1, 1, "2001-01-01")

        postgresDate = PostgresDate(date: Date(timeIntervalSinceReferenceDate: 3661.1), in: pacificTimeZone)
        checkPostgresDate(postgresDate, 2000, 12, 31, "2000-12-31")


        //
        // Additional test cases for init(_:).
        //

        // Invalid string representation should fail.
        XCTAssertNil(PostgresDate("foo"))

        // Invalid string representation should fail.
        XCTAssertNil(PostgresDate("2019-00-01"))

        // Valid string representation should succeed.
        postgresDate = PostgresDate("2019-01-02")
        checkPostgresDate(postgresDate, 2019, 1, 2, "2019-01-02")
    }
    
    func checkPostgresDate(
        _ postgresDate: PostgresDate?,
        _ expectedYear: Int, _ expectedMonth: Int, _ expectedDay: Int,
        _ expectedDescription: String) {
        
        if postgresDate == nil {
            XCTAssertNotNil(postgresDate)
            return
        }
        
        let postgresDate = postgresDate!
        
        var expectedDateComponents = DateComponents()
        expectedDateComponents.year = expectedYear
        expectedDateComponents.month = expectedMonth
        expectedDateComponents.day = expectedDay
        
        let expectedUtcDate: Date = {
            var dc = expectedDateComponents
            dc.hour = 0; dc.minute = 0; dc.second = 0; dc.nanosecond = 0
            dc.timeZone = utcTimeZone
            return utcCalendar.date(from: dc)! }()
        
        let expectedPacificDate: Date = {
            var dc = expectedDateComponents
            dc.hour = 0; dc.minute = 0; dc.second = 0; dc.nanosecond = 0
            dc.timeZone = pacificTimeZone
            return utcCalendar.date(from: dc)! }()
        
        let expectedPostgresValue = expectedDescription.postgresValue
        
        // Helper function for what's below...
        func checkPostgresDate(_ pd: PostgresDate) {
            
            let pdDateComponents = pd.dateComponents
            let pdUtcDate = pd.date(in: utcTimeZone)
            let pdPacificDate = pd.date(in: pacificTimeZone)
            let pdPostgresValue = pd.postgresValue
            let pdDescription = pd.description
            
            XCTAssert(pdDateComponents.isValidDate(in: utcCalendar))
            XCTAssertApproximatelyEqual(pdDateComponents, expectedDateComponents)
            XCTAssertApproximatelyEqual(pdUtcDate, expectedUtcDate)
            XCTAssertApproximatelyEqual(pdPacificDate, expectedPacificDate)
            XCTAssertEqual(pdPostgresValue, expectedPostgresValue)
            XCTAssertEqual(pdDescription, expectedDescription)
        }
        
        // Check the supplied PostgresDate.
        checkPostgresDate(postgresDate)
        
        // Check init(date:in:).
        checkPostgresDate(PostgresDate(date: expectedUtcDate, in: utcTimeZone))
        checkPostgresDate(PostgresDate(date: expectedPacificDate, in: pacificTimeZone))
        
        // Check Date.postgresDate(in:).
        checkPostgresDate(expectedUtcDate.postgresDate(in: utcTimeZone))
        checkPostgresDate(expectedPacificDate.postgresDate(in: pacificTimeZone))
        
        // Check init(_:).
        checkPostgresDate(PostgresDate(expectedDescription)!)
    }
}

// EOF
