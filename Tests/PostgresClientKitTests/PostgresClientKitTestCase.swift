//
//  PostgresClientKitTestCase.swift
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

import XCTest

/// A base class for testing PostgresClientKit.
class PostgresClientKitTestCase: XCTestCase {
    
    /// The en_US_POSIX locale.
    let enUsPosixLocale = Locale(identifier: "en_US_POSIX")
    
    /// The UTC/GMT time zone.
    let utcTimeZone = TimeZone(secondsFromGMT: 0)!
    
    /// The PST/PDT time zone.
    let pacificTimeZone = TimeZone.init(identifier: "America/Los_Angeles")!
    
    #if os(Linux) // temporary workaround for https://bugs.swift.org/browse/SR-10515
    
        /// A calendar based on the `en_US_POSIX` locale and the UTC/GMT time zone.
        internal var enUsPosixUtcCalendar: Calendar {
            _enUsPosixUtcCalendar.timeZone = utcTimeZone
            return _enUsPosixUtcCalendar
        }
    
        private var _enUsPosixUtcCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: "en_US_POSIX")
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!    
            return calendar
        }()
    
    #else
    
        /// A calendar based on the `en_US_POSIX` locale and the UTC/GMT time zone.
        internal lazy var enUsPosixUtcCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = enUsPosixLocale
            calendar.timeZone = utcTimeZone
            return calendar
        }()
    
    #endif
    
    /// Asserts two values are either both `nil` or both non-`nil`.
    func XCTAssertBothNilOrBothNotNil<T>(_ value1: T?, _ value2: T?,
                                         _ message: String = "XCTAssertBothNilOrBothNotNil",
                                         file: StaticString = #file, line: UInt = #line) {
        XCTAssert(
            (value1 == nil && value2 == nil) ||
            (value1 != nil && value2 != nil),
            "\(message): \(String(describing: value1)) and \(String(describing: value2))",
            file: file, line: line)
    }
    
    /// Two `Date` instances are "approximately equal" if their `timeSinceReferenceDate` values,
    /// rounded to millisecond precision, are equal.
    ///
    /// The PostgresClientKit tests use this definition for two reasons:
    ///
    /// - `DateFormatter` retains only millisecond precision (truncating additional digits in
    ///   converting strings to dates, and rounding in converting from dates to string).
    ///
    /// - Because `Date` is implemented on a `Double`, lossless conversion between `Date`
    ///   and `DateComponents` (whose `nanoseconds` property is an `Int`) is not possible for
    ///   some date values.
    @nonobjc func XCTAssertApproximatelyEqual(_ date1: Date, _ date2: Date,
                                              _ message: String = "XCTAssertApproximatelyEqual",
                                              file: StaticString = #file, line: UInt = #line) {
        
        let milliseconds1 = (date1.timeIntervalSinceReferenceDate * 1000.0).rounded()
        let milliseconds2 = (date2.timeIntervalSinceReferenceDate * 1000.0).rounded()
        
        XCTAssertEqual(
            milliseconds1, milliseconds2,
            "\(message): \(date1) and \(date2)",
            file: file, line: line)
    }
    
    /// Two `DateComponent` instances are "approximately equal" if each of the following conditions
    /// are met:
    ///
    /// - their `calendar`, `timeZone`, and `era` properties are equal
    ///
    /// - the properties for their other components are either both `nil` or both non-`nil`
    ///
    /// - calling `Calendar.date(from:)` on them produces two `Date` instances that are themselves
    ///   "approximately equal"
    @nonobjc func XCTAssertApproximatelyEqual(_ dc1: DateComponents,
                                              _ dc2: DateComponents,
                                              file: StaticString = #file, line: UInt = #line) {
        
        XCTAssertEqual(
            dc1.calendar, dc2.calendar,
            "DateComponents.calendar",
            file: file, line: line)
        
        XCTAssertEqual(
            dc1.timeZone, dc2.timeZone,
            "DateComponents.timeZone",
            file: file, line: line)
        
        XCTAssertEqual(
            dc1.era, dc2.era,
            "DateComponents.era",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.year, dc2.year,
            "DateComponents.year",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.yearForWeekOfYear, dc2.yearForWeekOfYear,
            "DateComponents.yearForWeekOfYear",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.quarter, dc2.quarter,
            "DateComponents.quarter",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.month, dc2.month,
            "DateComponents.month",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.weekOfMonth, dc2.weekOfMonth,
            "DateComponents.weekOfMonth",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.weekOfYear, dc2.weekOfYear,
            "DateComponents.weekOfYear",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.weekday, dc2.weekday,
            "DateComponents.weekday",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.weekdayOrdinal, dc2.weekdayOrdinal,
            "DateComponents.weekdayOrdinal",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.day, dc2.day,
            "DateComponents.day",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.hour, dc2.hour,
            "DateComponents.hour",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.minute, dc2.minute,
            "DateComponents.minute",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.second, dc2.second,
            "DateComponents.second",
            file: file, line: line)
        
        XCTAssertBothNilOrBothNotNil(
            dc1.nanosecond, dc2.nanosecond,
            "DateComponents.nanosecond",
            file: file, line: line)
        
        let date1 = enUsPosixUtcCalendar.date(from: dc1)
        let date2 = enUsPosixUtcCalendar.date(from: dc2)
        
        if let date1 = date1, let date2 = date2 {
            XCTAssertApproximatelyEqual(date1, date2, "DateComponents", file: file, line: line)
        } else {
            XCTAssertBothNilOrBothNotNil(date1, date2, "DateComponents", file: file, line: line)
        }
    }
}

// EOF
