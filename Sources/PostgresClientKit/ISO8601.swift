//
//  ISO8601.swift
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

import Foundation

/// Processes ISO 8601 dates and times.
internal class ISO8601 {
    
    //
    // MARK: Parsing string representations
    //

    /// Gets a `Date` for the moment of time described by the specified string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSSxxxxx` (for example, `2019-03-14 16:25:19.365+00:00`) or
    /// `yyyy-MM-dd HH:mm:ssxxxxx` (for example, `2019-03-14 16:25:19+00:00`).
    ///
    /// - Parameter value: the string
    /// - Returns: the `Date`, or `nil` if the string is invalid
    internal static func parseTimestampWithTimeZone(_ value: String) -> Date? {
        do {
            let parser = ISO8601(value)
            try parser.optionalWhitespace()
            try parser.date()
            try parser.whitespace()
            try parser.time()
            try parser.optionalWhitespace()
            try parser.timeZone()
            try parser.optionalWhitespace()
            try parser.end()
            return validateDateComponents(parser.dateComponents)?.date
        } catch {
            return nil
        }
    }
    
    /// Gets a `DateComponents` for the specified string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSS` (for example, `2019-03-14 16:25:19.365`) or
    /// `yyyy-MM-dd HH:mm:ss` (for example, `2019-03-14 16:25:19`).
    ///
    /// The returned value has the following components set:
    ///
    /// - `year`
    /// - `month`
    /// - `day`
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    ///
    /// - Parameter value: the string
    /// - Returns: the `DateComponents`, or `nil` if the string is invalid
    internal static func parseTimestamp(_ value: String) -> DateComponents? {
        do {
            let parser = ISO8601(value)
            try parser.optionalWhitespace()
            try parser.date()
            try parser.whitespace()
            try parser.time()
            try parser.optionalWhitespace()
            try parser.end()
            return validateDateComponents(parser.dateComponents, in: utcTimeZone)?.dateComponents
        } catch {
            return nil
        }
    }

    /// Gets a `DateComponents` for the specified string.
    ///
    /// The string must conform to the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd`.  For example, `2019-03-14`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `year`
    /// - `month`
    /// - `day`
    ///
    /// - Parameter value: the string
    /// - Returns: the `DateComponents`, or `nil` if the string is invalid
    internal static func parseDate(_ value: String) -> DateComponents? {
        do {
            let parser = ISO8601(value)
            try parser.optionalWhitespace()
            try parser.date()
            try parser.optionalWhitespace()
            try parser.end()
            return validateDateComponents(parser.dateComponents, in: utcTimeZone)?.dateComponents
        } catch {
            return nil
        }
    }

    /// Gets a `DateComponents` for the specified string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSS` (for example, `16:25:19.365`) or `HH:mm:ss` (for example, `16:25:19`).
    ///
    /// The returned value has the following components set:
    ///
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    ///
    /// - Parameter value: the string
    /// - Returns: the `DateComponents`, or `nil` if the string is invalid
    internal static func parseTime(_ value: String) -> DateComponents? {
        do {
            let parser = ISO8601(value)
            try parser.optionalWhitespace()
            try parser.time()
            try parser.optionalWhitespace()
            try parser.end()
            return validateDateComponents(parser.dateComponents, in: utcTimeZone)?.dateComponents
        } catch {
            return nil
        }
    }

    /// Gets a `DateComponents` for the specified string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSSxxxxx` (for example, `20:10:05.128-07:00`) or
    /// `HH:mm:ssxxxxx` (for example, `20:10:05-07:00`).
    ///
    /// The returned value has the following components set:
    ///
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    /// - `timeZone`
    ///
    /// - Parameter value: the string
    /// - Returns: the `DateComponents`, or `nil` if the string is invalid
    internal static func parseTimeWithTimeZone(_ value: String) -> DateComponents? {
        do {
            let parser = ISO8601(value)
            try parser.optionalWhitespace()
            try parser.time()
            try parser.optionalWhitespace()
            try parser.timeZone()
            try parser.optionalWhitespace()
            try parser.end()
            return validateDateComponents(parser.dateComponents)?.dateComponents
        } catch {
            return nil
        }
    }
    
    
    //
    // MARK: Forming string representations
    //
    
    /// Gets a string for the specified `Date` using the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSSxxxxx` (for example, `2019-03-14 16:25:19.365+00:00`).
    ///
    /// - Parameter date: the `Date`
    /// - Returns: the string
    internal static func formatTimestampWithTimeZone(date: Date) -> String {
        return timestampWithTimeZoneFormatter.string(from: date)
    }
    
    /// Gets a string for the specified `DateComponents` using the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSS` (for example, `2019-03-14 16:25:19.365`).
    ///
    /// - Parameter validatedDateComponents: the `DateComponents`; assumed to be valid
    /// - Returns: the string
    internal static func formatTimestamp(validatedDateComponents: DateComponents) -> String {
        let date = unvalidatedDate(from: validatedDateComponents, in: utcTimeZone)
        return timestampFormatter.string(from: date)
    }
    
    /// Gets a string for the specified `DateComponents` using the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd` (for example, `2019-03-14`).
    ///
    /// - Parameter validatedDateComponents: the `DateComponents`; assumed to be valid
    /// - Returns: the string
    internal static func formatDate(validatedDateComponents: DateComponents) -> String {
        var dc = validatedDateComponents
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        dc.nanosecond = 0
        let date = unvalidatedDate(from: dc, in: utcTimeZone)
        return dateFormatter.string(from: date)
    }
    
    /// Gets a string for the specified `DateComponents` using the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSS` (for example, `16:25:19.365`).
    ///
    /// - Parameter validatedDateComponents: the `DateComponents`; assumed to be valid
    /// - Returns: the string
    internal static func formatTime(validatedDateComponents: DateComponents) -> String {
        var dc = validatedDateComponents
        dc.year = 2000
        dc.month = 1
        dc.day = 1
        let date = unvalidatedDate(from: dc, in: utcTimeZone)
        return timeFormatter.string(from: date)
    }
    
    /// Gets a string for the specified `DateComponents` using the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSSxxxxx` (for example, `20:10:05.128-07:00`).
    ///
    /// - Parameter validatedDateComponents: the `DateComponents`; assumed to be valid
    /// - Returns: the string
    internal static func formatTimeWithTimeZone(validatedDateComponents: DateComponents) -> String {
        var dc = validatedDateComponents
        dc.year = 2000
        dc.month = 1
        dc.day = 1
        let date = unvalidatedDate(from: dc)
        return timeWithTimeZoneFormatterFor(timeZone: dc.timeZone!).string(from: date)
    }
    
    
    //
    // MARK: Conversion between Date and DateComponents
    //
    
    /// Validates the specified `DateComponents` value and converts them to a `Date`.
    ///
    /// The validation is performed using the time zone specified by either the value of the
    /// `timeZone` argument or the value of `dateComponents.timeZone`.  These are mutually
    /// exclusive and only one of them may be set.
    ///
    /// - Parameters:
    ///   - dateComponents: the value to validate
    ///   - timeZone: the time zone to use; see above
    /// - Returns: a (`DateComponents`, `Date`) tuple, or `nil` if invalid
    internal static func validateDateComponents(
        _ dateComponents: DateComponents, in timeZone: TimeZone? = nil) ->
        (dateComponents: DateComponents, date: Date)? {

        // DateComponents.isValidDate(in:) is buggy (https://bugs.swift.org/browse/SR-11569) and
        // slow (up to 114 us on Linux).  We can do better ourselves (~6 us).  The basic idea is
        // to see if we can convert from DateComponents to Date and back without changing the
        // DateComponents component values.  This approach exposes the Date as an interim result,
        // which is handy.
        
        // Compute a Date from the DateComponents.
        guard let (date, calendar) = dateAndCalendar(from: dateComponents, in: timeZone) else {
            return nil
        }

        // Convert that Date back to a second DateComponents instance.
        let dc = calendar.dateComponents(
            [ .year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)

        // For each DateComponents property of interest, check that the Date roundtrip preserved
        // its value.
        if (dateComponents.year     != nil && dc.year   != dateComponents.year) ||
            (dateComponents.month   != nil && dc.month  != dateComponents.month) ||
            (dateComponents.day     != nil && dc.day    != dateComponents.day) ||
            (dateComponents.hour    != nil && dc.hour   != dateComponents.hour) ||
            (dateComponents.minute  != nil && dc.minute != dateComponents.minute) ||
            (dateComponents.second  != nil && dc.second != dateComponents.second) {
            return nil
        }

        // Date is backed by a Double (minimum 15 digits precision).  This isn't quite sufficient
        // to roundtrip with microsecond precision (yet alone nanosecond).  So we just check the
        // roundtripped value to millisecond resolution.
        if dateComponents.nanosecond != nil &&
            abs(dc.nanosecond! - dateComponents.nanosecond!) >= 001_000_000 {
            return nil
        }

        // The DateComponents instance is valid.
        return (dateComponents, date)
    }
    
    /// Gets a `Date` for the specified `DateComponents` without validating that `DateComponents`.
    ///
    /// The conversion is performed using the time zone specified by either the value of the
    /// `timeZone` argument or the value of `dateComponents.timeZone`.  These are mutually
    /// exclusive and only one of them may be set.
    ///
    /// - Parameters:
    ///   - dateComponents: the `DateComponents` to convert
    ///   - timeZone: the time zone to use; see above
    /// - Returns: the `Date`
    internal static func unvalidatedDate(from dateComponents: DateComponents,
                                         in timeZone: TimeZone? = nil) -> Date {
        return dateAndCalendar(from: dateComponents, in: timeZone)!.date
    }
    
    /// Gets the `DateComponents` for the specified `Date`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `year`
    /// - `month`
    /// - `day`
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    ///
    /// Note that neither `calendar` nor `timeZone` are set in the returned value.
    ///
    /// - Parameters:
    ///   - from: the `Date` to convert
    ///   - timeZone: the time zone to use
    /// - Returns: the `DateComponents`
    internal static func dateComponents(from date: Date, in timeZone: TimeZone) -> DateComponents {
        
        let calendar = calendarFor(timeZone: timeZone)
        
        let dc = calendar.dateComponents(
            [ .year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)

        return dc
    }
    
    
    //
    // MARK: Calendars and time zones
    //

    /// The UTC/GMT time zone.
    internal static let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    /// A calendar for the UTC/GMT time zone.
    internal static let enUsPosixUtcCalendar = calendarFor(timeZone: utcTimeZone)
    
    /// Gets whether the specified `TimeZone` has a fixed offset from UTC/GMT (the offset does not
    /// change due to daylight savings time).
    ///
    /// - Parameter timeZone: the `TimeZone` to test
    /// - Returns: whether it has a fixed offset from UTC/GMT
    internal static func timeZoneHasFixedOffsetFromUTC(_ timeZone: TimeZone) -> Bool {
        
        let fixedOffset: Bool
        
        #if os(Linux)  // temporary workaround for https://bugs.swift.org/browse/SR-10516
        fixedOffset = timeZone.nextDaylightSavingTimeTransition == nil ||
                timeZone.nextDaylightSavingTimeTransition?.timeIntervalSinceReferenceDate == 0.0
        #else
        fixedOffset = timeZone.nextDaylightSavingTimeTransition == nil
        #endif
        
        return fixedOffset
    }
    

    //
    // MARK: Parser implementation
    //

    private struct ParseError: Error { }

    private init(_ value: String) {
        self.value = value
        index = value.startIndex
        dateComponents = DateComponents()
    }

    private let value: String                   // the string to parse
    private var index: String.Index             // parser's current position in that string
    private var dateComponents: DateComponents  // accumulates the parse output

    private func date() throws {
        dateComponents.year = try digits()
        try dash()
        dateComponents.month = try digits()
        try dash()
        dateComponents.day = try digits()
    }

    private func time() throws {

        // We try to emulate DateFormatter.date(from:) using the "HH:mm:ss.SSS" date pattern (see
        // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns).  As
        // part of this, we truncate fractional seconds after three digits (millisecond resolution).
        // This works well, since conversions to Date (which is backed by a 64-bit Double) are lossy
        // even for microseconds, yet alone nanoseconds.

        dateComponents.hour = try digits()
        try colon()
        dateComponents.minute = try digits()
        try colon()
        dateComponents.second = try digits()

        if try !atEnd && peek() == "." {
            _ = try next()
            dateComponents.nanosecond = try fractionalDigits(denominator: 1_000) * 1_000_000
        } else {
            dateComponents.nanosecond = 0
        }
    }

    private func timeZone() throws {

        // We try to emulate DateFormatter.date(from:) using the "xxxxx" date pattern (see
        // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns).
        //
        // Timezone Offset
        // -------- ------
        // Z        0
        // +1       3600
        // +01      3600
        // +12      43200   (New Zealand)
        // +145     6300
        // +0145    6300
        // +1245    45900   (Chatham Islands)
        // +1:45    6300    (not allowed by DateFormatter, but previously allowed by PostgresTimeWithTimeZone)
        // +12:45   45900
        //
        // +1:0     invalid
        // +13:0    invalid
        //
        // (and similarly for "-" instead of "+")

        var offsetSign = 1              // +1 or -1 for positive/negative offsets from GMT
        var colonPosition: Int? = nil   // number of digits before the colon appears
        let timeZone: TimeZone

        switch try next() {

        case "Z":
            timeZone = ISO8601.utcTimeZone

        case "-":
            offsetSign = -1
            fallthrough

        case "+":
            var digits = [Int]()

            while !atEnd && digits.count < 4 {
                let ch = try next()
                switch ch {

                case ":":
                    if colonPosition != nil { throw ParseError() } // can have only one colon
                    colonPosition = digits.count

                case "0": digits.append(0)
                case "1": digits.append(1)
                case "2": digits.append(2)
                case "3": digits.append(3)
                case "4": digits.append(4)
                case "5": digits.append(5)
                case "6": digits.append(6)
                case "7": digits.append(7)
                case "8": digits.append(8)
                case "9": digits.append(9)

                default:
                    break
                }
            }

            switch (colonPosition, digits.count) {
            case (nil, _):  break // no colon, ok
            case (1, 3):    break // "+1:30", ok
            case (2, 4):    break // "+01:30", ok
            default:        throw ParseError()
            }

            let offset: Int
            switch digits.count {
            case 1: offset =  3600 * digits[0]
            case 2: offset = 36000 * digits[0] + 3600 * digits[1]
            case 3: offset =  3600 * digits[0] +  600 * digits[1] +  60 * digits[2]
            case 4: offset = 36000 * digits[0] + 3600 * digits[1] + 600 * digits[2] + 60 * digits[3]
            default: throw ParseError()
            }

            timeZone = try ISO8601.timeZoneFor(secondsFromGMT: offsetSign * offset)

        default:
            throw ParseError()
        }

        dateComponents.timeZone = timeZone
    }
    
    
    //
    // MARK: Low-level parse methods
    //
    
    /// Are we at the end of the input string?
    private var atEnd: Bool {
        return index == value.endIndex
    }

    /// Gets the next character without consuming it.
    private func peek() throws -> Character {
        if atEnd { throw ParseError() }
        return value[index]
    }

    /// Consumes the next character.
    private func next() throws -> Character {
        let next = try peek()
        index = value.index(after: index)
        return next
    }

    /// Consumes zero or more spaces.
    private func optionalWhitespace() throws {
        while try !atEnd && peek() == " " {
            _ = try next()
        }
    }

    /// Consumes one or more spaces.
    private func whitespace() throws {
        if try next() != " " {
            throw ParseError()
        }

        try optionalWhitespace()
    }

    /// Consumes a dash.
    private func dash() throws {
        if try next() != "-" {
            throw ParseError()
        }
    }

    /// Consumes a colon.
    private func colon() throws {
        if try next() != ":" {
            throw ParseError()
        }
    }

    /// Consumes one or more digits, 0 to 9.
    private func digits() throws -> Int {

        var value = -1

        while !atEnd {
            let ch = try peek()
            if ch < "0" || ch > "9" { break }
            value = (value == -1 ? 0 : 10 * value) + Int(try next().wholeNumberValue!)
        }

        if value == -1 {
            throw ParseError()
        }

        return value
    }

    /// Consumes one or more digits to the right of the (already consumed) decimal point.
    private func fractionalDigits(denominator: Int) throws -> Int {

        var value = -1
        var multiplier = denominator / 10

        while !atEnd {
            let ch = try peek()
            if ch < "0" || ch > "9" { break }
            value = (value == -1 ? 0 : value) + multiplier * Int(try next().wholeNumberValue!)
            multiplier /= 10
        }

        if value == -1 {
            throw ParseError()
        }

        return value
    }

    /// Checks we are at the end of the input string.
    private func end() throws {
        if !atEnd {
            throw ParseError()
        }
    }

    
    //
    // MARK: TimeZone cache
    //
    // TimeZone(secondsFromGMT:) takes about 3 us, so it's worth caching them.
    //

    private static var timeZones = [Int : TimeZone]()
    private static let timeZonesSemaphore = DispatchSemaphore(value: 1)

    private static func timeZoneFor(secondsFromGMT: Int) throws -> TimeZone {

        timeZonesSemaphore.wait()
        defer { timeZonesSemaphore.signal() }

        if let timeZone = timeZones[secondsFromGMT] {
            return timeZone
        }

        guard let timeZone = TimeZone(secondsFromGMT: secondsFromGMT) else {
            throw ParseError()
        }

        timeZones[secondsFromGMT] = timeZone
        Postgres.logger.fine("Created time zone \(timeZone)")

        return timeZone
    }


    //
    // MARK: Calendar cache
    //
    // Creating a Calendar instance is slow, whether by initializing one and setting its properties
    // (about 20 us), or copying an existing instance and tweaking the time zone (about 11 us).  So
    // it's worthwhile caching them.
    //

    private static var calendars = [TimeZone : Calendar]()
    private static let calendarsSemaphore = DispatchSemaphore(value: 1)

    private static func calendarFor(timeZone: TimeZone) -> Calendar {

        calendarsSemaphore.wait()
        defer { calendarsSemaphore.signal() }

        if let calendar = calendars[timeZone] {
            assert(calendar.timeZone == timeZone)
            return calendar
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Postgres.enUsPosixLocale
        calendar.timeZone = timeZone
        
        calendars[timeZone] = calendar
        Postgres.logger.fine("Created calendar \(calendar) for time zone \(timeZone)")

        return calendar
    }
    
    
    //
    // MARK: DateFormatters used to form string representations
    //
    
    private static let timestampWithTimeZoneFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSxxxxx"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = utcTimeZone
        return df
    }()

    private static let timestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = utcTimeZone
        return df
    }()

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = utcTimeZone
        return df
    }()
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = enUsPosixUtcCalendar
        df.dateFormat = "HH:mm:ss.SSS"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = utcTimeZone
        return df
    }()
    
    // For PostgresTimeWithTimeZone values, a different formatter is required for each time zone.
    private static var timeWithTimeZoneFormatters = [TimeZone : DateFormatter]()
    private static let timeWithTimeZoneFormattersSemaphore = DispatchSemaphore(value: 1)

    private static func timeWithTimeZoneFormatterFor(timeZone: TimeZone) -> DateFormatter {

        timeWithTimeZoneFormattersSemaphore.wait()
        defer { timeWithTimeZoneFormattersSemaphore.signal() }

        if let formatter = timeWithTimeZoneFormatters[timeZone] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.calendar = calendarFor(timeZone: timeZone)
        formatter.dateFormat = "HH:mm:ss.SSSxxxxx"
        formatter.locale = Postgres.enUsPosixLocale
        formatter.timeZone = timeZone

        timeWithTimeZoneFormatters[timeZone] = formatter
        Postgres.logger.fine("Created timeWithTimeZoneFormatter for \(timeZone)")

        return formatter
    }
    
    
    //
    // MARK: Other implementation
    //
    
    private static func dateAndCalendar(
        from dateComponents: DateComponents, in timeZone: TimeZone?)
        -> (date: Date, calendar: Calendar)? {
        
        // Check that the calendar property of DateComponents has not been set.  Doing so can
        // be expensive if the timeZone property is already set to a different time zone than
        // that of the calendar.
        assert(dateComponents.calendar == nil)

        // The time zone should be either specified by the caller or already set on the
        // DateComponents, but not both.
        assert (
            (timeZone != nil && dateComponents.timeZone == nil) ||
            (timeZone == nil && dateComponents.timeZone != nil))
        let timeZone = timeZone ?? dateComponents.timeZone!

        // Get a Calendar instance for the selected time zone.  This makes Calendar.date(from:)
        // faster.  It also works around https://bugs.swift.org/browse/SR-10515.
        let calendar = calendarFor(timeZone: timeZone)

        // Calendar.date(from:) is also faster if the DateComponents timeZone property is nil.
        var dc = dateComponents
        dc.timeZone = nil
        
        guard let date = calendar.date(from: dc) else {
            return nil
        }
        
        return (date, calendar)
    }
}

// EOF
