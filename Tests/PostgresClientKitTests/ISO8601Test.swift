//
//  ISO8601Test.swift
//  PostgresClientKit
//
//  Copyright 2021 David Pitfield and the PostgresClientKit contributors
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

@testable import PostgresClientKit
import XCTest

/// Tests ISO8601.
class ISO8601Test: PostgresClientKitTestCase {
   
    func testParseTimestampWithTimeZone() {
                
        func check(
            _ string: String,
            _ year: Int, _ month: Int, _ day: Int,
            _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int) {
                
            let date = ISO8601.parseTimestampWithTimeZone(string)

            if date == nil {
                XCTAssertNotNil(date)
                return
            }
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.year = year
            expectedDateComponents.month = month
            expectedDateComponents.day = day
            expectedDateComponents.hour = hour
            expectedDateComponents.minute = minute
            expectedDateComponents.second = second
            expectedDateComponents.nanosecond = nanosecond
            let expectedDate = enUsPosixUtcCalendar.date(from: expectedDateComponents)!
            
            XCTAssertApproximatelyEqual(date!, expectedDate)
        }
        
        func checkInvalid(_ string: String) {
            XCTAssertNil(ISO8601.parseTimestampWithTimeZone(string))
        }
        
        // Basic
        check("2001-02-03 12:34:56.789Z", 2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2000-12-23 04:05:06.789Z", 2000, 12, 23, 4, 5, 6, 789_000_000)
        checkInvalid("*2000-12-23 04:05:06.789Z")
        checkInvalid("2000*12-23 04:05:06.789Z")
        checkInvalid("2000-*2-23 04:05:06.789Z")
        checkInvalid("2000-12*23 04:05:06.789Z")
        checkInvalid("2000-12-*3 04:05:06.789Z")
        checkInvalid("2000-12-23*04:05:06.789Z")
        checkInvalid("2000-12-23 *4:05:06.789Z")
        checkInvalid("2000-12-23 04*05:06.789Z")
        checkInvalid("2000-12-23 04:*5:06.789Z")
        checkInvalid("2000-12-23 04:05*06.789Z")
        checkInvalid("2000-12-23 04:05:*6.789Z")
        checkInvalid("2000-12-23 04:05:06*789Z")
        checkInvalid("2000-12-23 04:05:06.*89Z")
        checkInvalid("2000-12-23 04:05:06.789*")
        checkInvalid("2000-12-23 04:05:06.789Z*")
        checkInvalid("")
        checkInvalid(" ")
        checkInvalid("2000")

        // Optional whitespace
        check("  2001-02-03 12:34:56.789  Z  ", 2001, 2, 3, 12, 34, 56, 789_000_000)
        check("  2001-02-03 12:34:56.789  +00  ", 2001, 2, 3, 12, 34, 56, 789_000_000)

        // Required whitespace
        check("2001-02-03   12:34:56.789Z", 2001, 2, 3, 12, 34, 56, 789_000_000)
        checkInvalid("2001-02-0312:34:56.789Z")
        
        // Optional fractional seconds
        check("2001-02-03 12:34:56Z", 2001, 2, 3, 12, 34, 56, 000_000_000)
        checkInvalid("2001-02-03 12:34:56.Z")

        // Fractional seconds truncated after 3 digits
        check("2001-02-03 12:34:56.123456789Z", 2001, 2, 3, 12, 34, 56, 123_000_000)
        check("2001-02-03 12:34:56.987654321Z", 2001, 2, 3, 12, 34, 56, 987_000_000)
        check("2001-02-03 12:34:56.999999999Z", 2001, 2, 3, 12, 34, 56, 999_000_000)

        // Time zone
        check("2001-02-03 12:34:56.789+0",     2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+1",     2001, 2, 3, 11, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+00",    2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+01",    2001, 2, 3, 11, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+12",    2001, 2, 3,  0, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+000",   2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+100",   2001, 2, 3, 11, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+145",   2001, 2, 3, 10, 49, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+0000",  2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+0100",  2001, 2, 3, 11, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+0145",  2001, 2, 3, 10, 49, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+1245",  2001, 2, 2, 23, 49, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+1:45",  2001, 2, 3, 10, 49, 56, 789_000_000)
        check("2001-02-03 12:34:56.789+12:45", 2001, 2, 2, 23, 49, 56, 789_000_000)
        checkInvalid("2001-02-03 12:34:56.789+1:0")
        checkInvalid("2001-02-03 12:34:56.789+13:0")
        checkInvalid("2001-02-03 12:34:56.789+1:3:0")
        check("2001-02-03 12:34:56.789-0",     2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-1",     2001, 2, 3, 13, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-00",    2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-01",    2001, 2, 3, 13, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-12",    2001, 2, 4,  0, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-000",   2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-100",   2001, 2, 3, 13, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-145",   2001, 2, 3, 14, 19, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-0000",  2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-0100",  2001, 2, 3, 13, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-0145",  2001, 2, 3, 14, 19, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-1245",  2001, 2, 4,  1, 19, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-1:45",  2001, 2, 3, 14, 19, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-12:45", 2001, 2, 4,  1, 19, 56, 789_000_000)
        checkInvalid("2001-02-03 12:34:56.789-1:0")
        checkInvalid("2001-02-03 12:34:56.789-13:0")
        checkInvalid("2001-02-03 12:34:56.789-1:3:0")
        check("2001-02-03 12:34:56.789-06:07",     2001, 2, 3, 18, 41, 56, 789_000_000)
        check("2001-02-03 12:34:56.789-08:09",     2001, 2, 3, 20, 43, 56, 789_000_000)
        checkInvalid("2001-02-03 12:34:56.789+")
        checkInvalid("2001-02-03 12:34:56.789-")
        
        // Invalid component values
        checkInvalid("2001-00-03 12:34:56.789Z")
        checkInvalid("2001-13-03 12:34:56.789Z")
        checkInvalid("2001-02-00 12:34:56.789Z")
        checkInvalid("2001-02-29 12:34:56.789Z")
        checkInvalid("2001-02-03 24:34:56.789Z")
        checkInvalid("2001-02-03 12:60:56.789Z")
        checkInvalid("2001-02-03 12:34:61.789Z")
    }

    func testParseTimestamp() {
                
        func check(
            _ string: String,
            _ year: Int, _ month: Int, _ day: Int,
            _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int) {
                
            let dateComponents = ISO8601.parseTimestamp(string)

            if dateComponents == nil {
                XCTAssertNotNil(dateComponents)
                return
            }
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.year = year
            expectedDateComponents.month = month
            expectedDateComponents.day = day
            expectedDateComponents.hour = hour
            expectedDateComponents.minute = minute
            expectedDateComponents.second = second
            expectedDateComponents.nanosecond = nanosecond
            
            XCTAssertApproximatelyEqual(dateComponents!, expectedDateComponents)
        }
        
        func checkInvalid(_ string: String) {
            XCTAssertNil(ISO8601.parseTimestamp(string))
        }
        
        // Basic
        check("2001-02-03 12:34:56.789", 2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2000-12-23 04:05:06.789", 2000, 12, 23, 4, 5, 6, 789_000_000)
        checkInvalid("*2000-12-23 04:05:06.789")
        checkInvalid("2000*12-23 04:05:06.789")
        checkInvalid("2000-*2-23 04:05:06.789")
        checkInvalid("2000-12*23 04:05:06.789")
        checkInvalid("2000-12-*3 04:05:06.789")
        checkInvalid("2000-12-23*04:05:06.789")
        checkInvalid("2000-12-23 *4:05:06.789")
        checkInvalid("2000-12-23 04*05:06.789")
        checkInvalid("2000-12-23 04:*5:06.789")
        checkInvalid("2000-12-23 04:05*06.789")
        checkInvalid("2000-12-23 04:05:*6.789")
        checkInvalid("2000-12-23 04:05:06*789")
        checkInvalid("2000-12-23 04:05:06.*89")
        checkInvalid("2000-12-23 04:05:06.789*")
        checkInvalid("")
        checkInvalid(" ")
        checkInvalid("2000")

        // Optional whitespace
        check("  2001-02-03 12:34:56.789  ", 2001, 2, 3, 12, 34, 56, 789_000_000)

        // Required whitespace
        check("2001-02-03   12:34:56.789", 2001, 2, 3, 12, 34, 56, 789_000_000)
        checkInvalid("2001-02-0312:34:56.789")
        
        // Optional fractional seconds
        check("2001-02-03 12:34:56", 2001, 2, 3, 12, 34, 56, 000_000_000)
        checkInvalid("2001-02-03 12:34:56.")

        // Fractional seconds truncated after 3 digits
        check("2001-02-03 12:34:56.123456789", 2001, 2, 3, 12, 34, 56, 123_000_000)
        check("2001-02-03 12:34:56.987654321", 2001, 2, 3, 12, 34, 56, 987_000_000)
        check("2001-02-03 12:34:56.999999999", 2001, 2, 3, 12, 34, 56, 999_000_000)

        // Invalid component values
        checkInvalid("2001-00-03 12:34:56.789")
        checkInvalid("2001-13-03 12:34:56.789")
        checkInvalid("2001-02-00 12:34:56.789")
        checkInvalid("2001-02-29 12:34:56.789")
        checkInvalid("2001-02-03 24:34:56.789")
        checkInvalid("2001-02-03 12:60:56.789")
        checkInvalid("2001-02-03 12:34:61.789")
    }

    func testParseDate() {
                
        func check(
            _ string: String,
            _ year: Int, _ month: Int, _ day: Int) {
                
            let dateComponents = ISO8601.parseDate(string)

            if dateComponents == nil {
                XCTAssertNotNil(dateComponents)
                return
            }
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.year = year
            expectedDateComponents.month = month
            expectedDateComponents.day = day
            
            XCTAssertApproximatelyEqual(dateComponents!, expectedDateComponents)
        }
        
        func checkInvalid(_ string: String) {
            XCTAssertNil(ISO8601.parseDate(string))
        }
        
        // Basic
        check("2001-02-03", 2001, 2, 3)
        check("2000-12-23", 2000, 12, 23)
        checkInvalid("*2000-12-23")
        checkInvalid("2000*12-23")
        checkInvalid("2000-*2-23")
        checkInvalid("2000-12*23")
        checkInvalid("2000-12-*3")
        checkInvalid("2000-12-23*")
        checkInvalid("")
        checkInvalid(" ")
        checkInvalid("2000")

        // Optional whitespace
        check("  2001-02-03  ", 2001, 2, 3)

        // Invalid component values
        checkInvalid("2001-00-03")
        checkInvalid("2001-13-03")
        checkInvalid("2001-02-00")
        checkInvalid("2001-02-29")
    }

    func testParseTime() {
                
        func check(
            _ string: String,
            _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int) {
                
            let dateComponents = ISO8601.parseTime(string)

            if dateComponents == nil {
                XCTAssertNotNil(dateComponents)
                return
            }
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.hour = hour
            expectedDateComponents.minute = minute
            expectedDateComponents.second = second
            expectedDateComponents.nanosecond = nanosecond
            
            XCTAssertApproximatelyEqual(dateComponents!, expectedDateComponents)
        }
        
        func checkInvalid(_ string: String) {
            XCTAssertNil(ISO8601.parseTime(string))
        }
        
        // Basic
        check("12:34:56.789", 12, 34, 56, 789_000_000)
        check("04:05:06.789", 4, 5, 6, 789_000_000)
        checkInvalid("*04:05:06.789")
        checkInvalid("04*05:06.789")
        checkInvalid("04:*5:06.789")
        checkInvalid("04:05*06.789")
        checkInvalid("04:05:*6.789")
        checkInvalid("04:05:06*789")
        checkInvalid("04:05:06.*89")
        checkInvalid("04:05:06.789*")
        checkInvalid("")
        checkInvalid(" ")
        checkInvalid("04")

        // Optional whitespace
        check("  12:34:56.789  ", 12, 34, 56, 789_000_000)

        // Optional fractional seconds
        check("12:34:56", 12, 34, 56, 000_000_000)
        checkInvalid("12:34:56.")

        // Fractional seconds truncated after 3 digits
        check("12:34:56.123456789", 12, 34, 56, 123_000_000)
        check("12:34:56.987654321", 12, 34, 56, 987_000_000)
        check("12:34:56.999999999", 12, 34, 56, 999_000_000)

        // Invalid component values
        checkInvalid("24:34:56.789")
        checkInvalid("12:60:56.789")
        checkInvalid("12:34:61.789")
    }

    func testParseTimesWithTimeZone() {
                
        func check(
            _ string: String,
            _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int, _ timeZone: TimeZone) {
                
            let dateComponents = ISO8601.parseTimeWithTimeZone(string)

            if dateComponents == nil {
                XCTAssertNotNil(dateComponents)
                return
            }
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.hour = hour
            expectedDateComponents.minute = minute
            expectedDateComponents.second = second
            expectedDateComponents.nanosecond = nanosecond
            expectedDateComponents.timeZone = timeZone
            
            XCTAssertApproximatelyEqual(dateComponents!, expectedDateComponents)
        }
        
        func checkInvalid(_ string: String) {
            XCTAssertNil(ISO8601.parseTimeWithTimeZone(string))
        }
        
        let tzUTC = utcTimeZone
        let tzPlus0100 = TimeZone(secondsFromGMT: 3600)!
        let tzPlus0145 = TimeZone(secondsFromGMT: 6300)!
        let tzPlus1200 = TimeZone(secondsFromGMT: 43200)!
        let tzPlus1245 = TimeZone(secondsFromGMT: 45900)!
        let tzMinus0100 = TimeZone(secondsFromGMT: -3600)!
        let tzMinus0145 = TimeZone(secondsFromGMT: -6300)!
        let tzMinus0607 = TimeZone(secondsFromGMT: -22020)!
        let tzMinus0809 = TimeZone(secondsFromGMT: -29340)!
        let tzMinus1200 = TimeZone(secondsFromGMT: -43200)!
        let tzMinus1245 = TimeZone(secondsFromGMT: -45900)!

        // Basic
        check("12:34:56.789Z", 12, 34, 56, 789_000_000, tzUTC)
        check("04:05:06.789Z", 4, 5, 6, 789_000_000, tzUTC)
        checkInvalid("*04:05:06.789Z")
        checkInvalid("04*05:06.789Z")
        checkInvalid("04:*5:06.789Z")
        checkInvalid("04:05*06.789Z")
        checkInvalid("04:05:*6.789Z")
        checkInvalid("04:05:06*789Z")
        checkInvalid("04:05:06.*89Z")
        checkInvalid("04:05:06.789*")
        checkInvalid("04:05:06.789Z*")
        checkInvalid("")
        checkInvalid(" ")
        checkInvalid("04")

        // Optional whitespace
        check("  12:34:56.789  Z  ", 12, 34, 56, 789_000_000, tzUTC)
        check("  12:34:56.789  +00  ", 12, 34, 56, 789_000_000, tzUTC)

        // Optional fractional seconds
        check("12:34:56Z", 12, 34, 56, 000_000_000, tzUTC)
        checkInvalid("12:34:56.Z")

        // Fractional seconds truncated after 3 digits
        check("12:34:56.123456789Z", 12, 34, 56, 123_000_000, tzUTC)
        check("12:34:56.987654321Z", 12, 34, 56, 987_000_000, tzUTC)
        check("12:34:56.999999999Z", 12, 34, 56, 999_000_000, tzUTC)
        
        // Time zone
        check("12:34:56.789+0",     12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789+1",     12, 34, 56, 789_000_000, tzPlus0100)
        check("12:34:56.789+00",    12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789+01",    12, 34, 56, 789_000_000, tzPlus0100)
        check("12:34:56.789+12",    12, 34, 56, 789_000_000, tzPlus1200)
        check("12:34:56.789+000",   12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789+100",   12, 34, 56, 789_000_000, tzPlus0100)
        check("12:34:56.789+145",   12, 34, 56, 789_000_000, tzPlus0145)
        check("12:34:56.789+0000",  12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789+0100",  12, 34, 56, 789_000_000, tzPlus0100)
        check("12:34:56.789+0145",  12, 34, 56, 789_000_000, tzPlus0145)
        check("12:34:56.789+1245",  12, 34, 56, 789_000_000, tzPlus1245)
        check("12:34:56.789+1:45",  12, 34, 56, 789_000_000, tzPlus0145)
        check("12:34:56.789+12:45", 12, 34, 56, 789_000_000, tzPlus1245)
        checkInvalid("12:34:56.789+1:0")
        checkInvalid("12:34:56.789+13:0")
        checkInvalid("12:34:56.789+1:3:0")
        check("12:34:56.789-0",     12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789-1",     12, 34, 56, 789_000_000, tzMinus0100)
        check("12:34:56.789-00",    12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789-01",    12, 34, 56, 789_000_000, tzMinus0100)
        check("12:34:56.789-12",    12, 34, 56, 789_000_000, tzMinus1200)
        check("12:34:56.789-000",   12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789-100",   12, 34, 56, 789_000_000, tzMinus0100)
        check("12:34:56.789-145",   12, 34, 56, 789_000_000, tzMinus0145)
        check("12:34:56.789-0000",  12, 34, 56, 789_000_000, tzUTC)
        check("12:34:56.789-0100",  12, 34, 56, 789_000_000, tzMinus0100)
        check("12:34:56.789-0145",  12, 34, 56, 789_000_000, tzMinus0145)
        check("12:34:56.789-1245",  12, 34, 56, 789_000_000, tzMinus1245)
        check("12:34:56.789-1:45",  12, 34, 56, 789_000_000, tzMinus0145)
        check("12:34:56.789-12:45", 12, 34, 56, 789_000_000, tzMinus1245)
        checkInvalid("12:34:56.789-1:0")
        checkInvalid("12:34:56.789-13:0")
        checkInvalid("12:34:56.789-1:3:0")
        check("12:34:56.789-06:07", 12, 34, 56, 789_000_000, tzMinus0607)
        check("12:34:56.789-08:09", 12, 34, 56, 789_000_000, tzMinus0809)
        checkInvalid("12:34:56.789+")
        checkInvalid("12:34:56.789-")

        // Invalid component values
        checkInvalid("24:34:56.789Z")
        checkInvalid("12:60:56.789Z")
        checkInvalid("12:34:61.789Z")
    }
    
    func testFormatTimestampWithTimeZone() {
                
        func check(_ string: String, _ expectedString: String) {
            let date = ISO8601.parseTimestampWithTimeZone(string)!
            let s = ISO8601.formatTimestampWithTimeZone(date: date)
            XCTAssertEqual(s, expectedString)
        }
        
        // Basic
        check("2001-02-03 12:34:56.789Z", "2001-02-03 12:34:56.789+00:00")
        check("2000-12-23 04:05:06.789Z", "2000-12-23 04:05:06.789+00:00")
        
        // Fractional seconds
        check("2000-12-23 04:05:06.000Z", "2000-12-23 04:05:06.000+00:00")
        check("2000-12-23 04:05:06Z", "2000-12-23 04:05:06.000+00:00")
        
        // Time zone
        check("2001-02-03 12:34:56.789+01:45", "2001-02-03 10:49:56.789+00:00")
        check("2001-02-03 12:34:56.789-01:45", "2001-02-03 14:19:56.789+00:00")
    }

    func testFormatTimestamp() {
                
        func check(_ string: String, _ expectedString: String) {
            let dateComponents = ISO8601.parseTimestamp(string)!
            let s = ISO8601.formatTimestamp(validatedDateComponents: dateComponents)
            XCTAssertEqual(s, expectedString)
        }
        
        // Basic
        check("2001-02-03 12:34:56.789", "2001-02-03 12:34:56.789")
        check("2000-12-23 04:05:06.789", "2000-12-23 04:05:06.789")
        
        // Fractional seconds
        check("2000-12-23 04:05:06.000", "2000-12-23 04:05:06.000")
        check("2000-12-23 04:05:06", "2000-12-23 04:05:06.000")
    }

    func testFormatDate() {
                
        func check(_ string: String, _ expectedString: String) {
            let dateComponents = ISO8601.parseDate(string)!
            let s = ISO8601.formatDate(validatedDateComponents: dateComponents)
            XCTAssertEqual(s, expectedString)
        }
        
        // Basic
        check("2001-02-03", "2001-02-03")
        check("2000-12-23", "2000-12-23")
    }

    func testFormatTime() {
                
        func check(_ string: String, _ expectedString: String) {
            let dateComponents = ISO8601.parseTime(string)!
            let s = ISO8601.formatTime(validatedDateComponents: dateComponents)
            XCTAssertEqual(s, expectedString)
        }
        
        // Basic
        check("12:34:56.789", "12:34:56.789")
        check("04:05:06.789", "04:05:06.789")
        
        // Fractional seconds
        check("04:05:06.000", "04:05:06.000")
        check("04:05:06", "04:05:06.000")
    }

    func testFormatTimeWithTimeZone() {
                
        func check(_ string: String, _ expectedString: String) {
            let dateComponents = ISO8601.parseTimeWithTimeZone(string)!
            let s = ISO8601.formatTimeWithTimeZone(validatedDateComponents: dateComponents)
            XCTAssertEqual(s, expectedString)
        }
        
        // Basic
        check("12:34:56.789Z", "12:34:56.789+00:00")
        check("04:05:06.789Z", "04:05:06.789+00:00")
        
        // Fractional seconds
        check("04:05:06.000Z", "04:05:06.000+00:00")
        check("04:05:06Z", "04:05:06.000+00:00")
        
        // Time zone
        check("12:34:56.789+01:45", "12:34:56.789+01:45")
        check("12:34:56.789-01:45", "12:34:56.789-01:45")
    }

    func testDateComponentsFromDate() {
                
        func check(
            _ string: String, _ timeZone: TimeZone,
            _ year: Int, _ month: Int, _ day: Int,
            _ hour: Int, _ minute: Int, _ second: Int, _ nanosecond: Int) {
            
            let date = ISO8601.parseTimestampWithTimeZone(string)!
            let dateComponents = ISO8601.dateComponents(from: date, in: timeZone)
            
            var expectedDateComponents = DateComponents()
            expectedDateComponents.year = year
            expectedDateComponents.month = month
            expectedDateComponents.day = day
            expectedDateComponents.hour = hour
            expectedDateComponents.minute = minute
            expectedDateComponents.second = second
            expectedDateComponents.nanosecond = nanosecond
            
            XCTAssertApproximatelyEqual(dateComponents, expectedDateComponents)
        }
        
        let tzUTC = utcTimeZone
        let tzPlus0100 = TimeZone(secondsFromGMT: 3600)!
        let tzMinus0100 = TimeZone(secondsFromGMT: -3600)!
        
        check("2001-02-03 12:34:56.789Z", tzUTC, 2001, 2, 3, 12, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789Z", tzPlus0100, 2001, 2, 3, 13, 34, 56, 789_000_000)
        check("2001-02-03 12:34:56.789Z", tzMinus0100, 2001, 2, 3, 11, 34, 56, 789_000_000)
    }
    
    func testTimeZoneHasFixedOffset() {

        let tzUTC = utcTimeZone
        let tzPlus0100 = TimeZone(secondsFromGMT: 3600)!
        let tzMinus0100 = TimeZone(secondsFromGMT: -3600)!
        let tzLosAngeles = TimeZone(identifier: "America/Los_Angeles")!
        
        XCTAssertTrue(ISO8601.timeZoneHasFixedOffsetFromUTC(tzUTC))
        XCTAssertTrue(ISO8601.timeZoneHasFixedOffsetFromUTC(tzPlus0100))
        XCTAssertTrue(ISO8601.timeZoneHasFixedOffsetFromUTC(tzMinus0100))
        XCTAssertFalse(ISO8601.timeZoneHasFixedOffsetFromUTC(tzLosAngeles))
    }

}

// EOF
