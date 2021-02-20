//
//  ExistingPerformance.swift
//  PostgresClientKitTests
//
//  Created by David Pitfield on 1/20/21.
//

import Foundation
import PostgresClientKit
import XCTest

class ExistingPerformance: XCTestCase {
    
    func test() throws {
        
        // Before (My Mac, release build):
        //
        // PostgresClientKit
        //    66.764 us PostgresValue(_:).timestampWithTimeZone().date     (10000 iterations) 2019-01-02 11:04:05 +0000
        //   170.522 us PostgresValue(_:).timestamp().date(in:)            (1000 iterations) 2019-01-02 11:04:05 +0000
        //   159.015 us PostgresValue(_:).date().date(in:)                 (1000 iterations) 2019-01-02 08:00:00 +0000
        //   165.569 us PostgresValue(_:).time().date(in: tz)              (1000 iterations) 2000-01-01 11:04:05 +0000
        //   290.003 us PostgresValue(_:).timeWithTimeZone().date          (1000 iterations) 2000-01-01 11:04:05 +0000
        // Prototypes for PostgresTimestamp
        //    21.414 us PostgresValue(_:).fastDateSwiftParser(timeZone:)   (10000 iterations) 2019-01-02 11:04:05 +0000
        //    23.878 us PostgresValue(_:).fastDateVsscanf(timeZone:)       (10000 iterations) 2019-01-02 11:04:05 +0000
        
        // After (My Mac, release build):
        //
        // PostgresClientKit
        //    11.273 us PostgresValue(_:).timestampWithTimeZone().date    (10000 iterations) 2019-01-02 11:04:05 +0000
        //    13.359 us PostgresValue(_:).timestamp().date(in:)           (10000 iterations) 2019-01-02 11:04:05 +0000
        //    12.897 us PostgresValue(_:).date().date(in:)                (10000 iterations) 2019-01-02 08:00:00 +0000
        //    15.855 us PostgresValue(_:).time().date(in: tz)             (10000 iterations) 2000-01-01 11:04:05 +0000
        //    13.471 us PostgresValue(_:).timeWithTimeZone().date         (10000 iterations) 2000-01-01 11:04:05 +0000
        // Prototypes for PostgresTimestamp
        //    22.036 us PostgresValue(_:).fastDateSwiftParser(timeZone:)  (10000 iterations) 2019-01-02 11:04:05 +0000
        //    23.291 us PostgresValue(_:).fastDateVsscanf(timeZone:)      (10000 iterations) 2019-01-02 11:04:05 +0000
        
        let tz = TimeZone.current
        
        //
        // Performance of current PostgresClientKit release
        //
        
        print("PostgresClientKit")
        
        try time("PostgresValue(_:).timestampWithTimeZone().date") {
            try PostgresValue("2019-01-02 03:04:05.365-08").timestampWithTimeZone().date
        }
        
        try time("PostgresValue(_:).timestamp().date(in:)") {
            try PostgresValue("2019-01-02 03:04:05.365").timestamp().date(in: tz)
        }
        
        try time("PostgresValue(_:).date().date(in:)") {
            try PostgresValue("2019-01-02").date().date(in: tz)
        }
        
        try time("PostgresValue(_:).time().date(in: tz)") {
            try PostgresValue("03:04:05.365").time().date(in: tz)
        }
        
        try time("PostgresValue(_:).timeWithTimeZone().date") {
            try PostgresValue("03:04:05.365-08").timeWithTimeZone().date
        }
        
        
        //
        // Prototypes: see https://gist.github.com/pitfield/b1791f1db72cadc9374b396a68d1f824
        //
        
        print("Prototypes for PostgresTimestamp")
        
        try time("PostgresValue(_:).fastDateSwiftParser(timeZone:)") {
            try PostgresValue("2019-01-02 03:04:05.365").fastDateSwiftParser(timeZone: tz)
        }
        
        try time("PostgresValue(_:).fastDateVsscanf(timeZone:)") {
            try PostgresValue("2019-01-02 03:04:05.365").fastDateVsscanf(timeZone: tz)
        }
    }
}

// From https://gist.github.com/pitfield/b1791f1db72cadc9374b396a68d1f824
private extension PostgresValue {
    
    func fastDateSwiftParser(timeZone: TimeZone) throws -> Date {
        
        try verifyNotNil()

        return try optionalFastDateSwiftParser(timeZone: timeZone)!
    }
    
    func optionalFastDateSwiftParser(timeZone: TimeZone) throws -> Date? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let dateComponents = PostgresValue.dateComponents(from: rawValue) else {
            throw conversionError(PostgresTimestamp.self)
        }
        
        return PostgresValue.date(in: timeZone, for: dateComponents)
    }

    // Warning - not thread safe!
    func fastDateVsscanf(timeZone: TimeZone) throws -> Date {
        
        try verifyNotNil()

        return try optionalFastDateVsscanf(timeZone: timeZone)!
    }
    
    // Warning - not thread safe!
    func optionalFastDateVsscanf(timeZone: TimeZone) throws -> Date? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let date = DateParserVsscanf.parse(rawValue, in: timeZone) else {
            throw conversionError(PostgresTimestamp.self)
        }
        
        return date
    }

    
    //
    // MARK: Copied from PostgresValue.swift to bring into scope
    //
    
    private func verifyNotNil() throws {
        if isNull {
            throw PostgresError.valueIsNil
        }
    }

    private func conversionError(_ type: Any.Type) -> Error {
        return PostgresError.valueConversionError(value: self, type: type)
    }
    

    //
    // MARK: Copied from Postgres.swift to bring into scope
    //
    
    private static let enUsPosixLocale = Locale(identifier: "en_US_POSIX")
    private static let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    private static let enUsPosixUtcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    
    /// Temnporary workaround for https://bugs.swift.org/browse/SR-11569.
    private static func isValidDate(_ dc: DateComponents) -> Bool {
        
        var calendar = dc.calendar ?? enUsPosixUtcCalendar
        
        if let timeZone = dc.timeZone {
            calendar.timeZone = timeZone
        }
        
        return dc.isValidDate(in: calendar)
    }


    //
    // MARK: fastDateSwiftParser
    //
    
    private static func dateComponents(from s: String) -> DateComponents? {
        
        struct ParseError: Error { }
        
        var index = s.startIndex

        func skipWhitespace() throws {
            while index != s.endIndex {
                if s[index] != " " { return }
                index = s.index(after: index)
            }
        }
        
        func nextCharacter() throws -> Character {
            if index == s.endIndex { throw ParseError() }
            let character = s[index]
            index = s.index(after: index)
            return character
        }
        
        func dash() throws {
            let character = try nextCharacter()
            if character != "-" { throw ParseError() }
        }
        
        func space() throws {
            let character = try nextCharacter()
            if character != " " { throw ParseError() }
        }
        
        func colon() throws {
            let character = try nextCharacter()
            if character != ":" { throw ParseError() }
        }
        
        func dot() throws {
            let character = try nextCharacter()
            if character != "." { throw ParseError() }
        }
        
        func digits(_ count: Int) throws -> Int {
            var value = 0
            for _ in 0..<count {
                let character = try nextCharacter()
                if character < "0" || character > "9" { throw ParseError() }
                value = 10 * value + character.wholeNumberValue!
            }
            return value
        }
        
        func done() throws {
            if index != s.endIndex {
                throw ParseError()
            }
        }
        
        do {
            try skipWhitespace()
            let year = try digits(4)
            try dash()
            let month = try digits(2)
            try dash()
            let day = try digits(2)
            try space()
            let hour = try digits(2)
            try colon()
            let minute = try digits(2)
            try colon()
            let second = try digits(2)
            var millisecond = 0
            
            if index != s.endIndex && s[index] == "." { // fractional seconds is allowed but not required
                try dot()
                millisecond = try digits(3)
            }
            
            try skipWhitespace()
            try done()
            
            var dc = DateComponents()
            dc.year = year
            dc.month = month
            dc.day = day
            dc.hour = hour
            dc.minute = minute
            dc.second = second
            dc.nanosecond = millisecond * 1_000_000

            guard isValidDate(dc) else { return nil }

            return dc
        } catch {
            return nil
        }
    }
    
    private static func date(in timeZone: TimeZone, for dateComponents: DateComponents) -> Date {
        let calendar = calendarFor(timeZone: timeZone)
        return calendar.date(from: dateComponents)! // validated components on the way in
    }
 
    // A cache of calendars for different time zones.
    private static var calendars = [TimeZone: Calendar]()
    private static let calendarsSemaphore = DispatchSemaphore(value: 1)
    
    private static func calendarFor(timeZone: TimeZone) -> Calendar {
        
        calendarsSemaphore.wait()
        defer { calendarsSemaphore.signal() }
        
        if let calendar = calendars[timeZone] {
            return calendar
        }
        
        var calendar = enUsPosixUtcCalendar
        calendar.timeZone = timeZone
        calendars[timeZone] = calendar
        
//        print("Created calendar for \(timeZone)")
        
        return calendar
    }
    
    
    //
    // MARK: fastDateVsscanf
    //
    // Based on https://gist.github.com/kkieffer/e312fe9d0d56e6aa104b884d4b2433ff
    //
    
    class DateParserVsscanf {
        
        private static var components = DateComponents()
        
        private static let year = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private static let month = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private static let day = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private static let hour = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private static let minute = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        private static let second = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        
        static func parse(_ dateString: String, in timezone: TimeZone) -> Date? {
            
            let _ = withVaList([year, month, day, hour, minute, second], { pointer in
                vsscanf(dateString, "%d-%d-%d %d:%d:%f", pointer)
            })
            
            components.year = Int(year.pointee)
            components.minute = Int(minute.pointee)
            components.day = Int(day.pointee)
            components.hour = Int(hour.pointee)
            components.month = Int(month.pointee)
            components.second = Int(second.pointee)
            
            // @pitfield: Handle milliseconds
            let milliseconds = Int((second.pointee - Float(components.second!)) * 1000)
            components.nanosecond = milliseconds * 1_000_000
            
            // @pitfield: Necessary to detect invalid dates, e.g. 2020-01-222 12:34:56.789
            guard isValidDate(components) else { return nil }

            // @pitfield: Faster to reuse Calendar instances
            let calendar = PostgresValue.calendarFor(timeZone: timezone)

//            var calendar = Calendar(identifier: .gregorian)
//            calendar.timeZone = timezone
//            calendar.locale = Locale(identifier: "en_US_POSIX")
            
            return calendar.date(from: components)
        }
    }
}

// EOF
