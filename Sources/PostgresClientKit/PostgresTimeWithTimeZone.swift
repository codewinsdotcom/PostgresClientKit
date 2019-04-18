//
//  PostgresTimeWithTimeZone.swift
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

import Foundation

/// Represents a Postgres `TIME WITH TIME ZONE` value, which consists of the following components:
///
/// - hour
/// - minute
/// - seconds (and fractional seconds)
/// - time zone (expressed as an offset from UTC/GMT)
///
/// For example, `20:10:05.128-07:00`.
///
/// Unlike `TIMESTAMP WITH TIME ZONE`, a `TIME WITH TIME ZONE` value is not normalized to UTC/GMT;
/// the time zone in which it is specified is preserved.
///
/// Like Foundation `DateComponents`, PostgresClientKit records fractional seconds in nanoseconds.
/// However, [due to a bug](https://stackoverflow.com/questions/23684727) in the Foundation
/// `DateFormatter` class, only 3 fractional digits are preserved (millisecond resolution) in
/// values sent to and received from the Postgres server.
public struct PostgresTimeWithTimeZone: PostgresValueConvertible, CustomStringConvertible {
    
    /// Creates a `PostgresTimeWithTimeZone` from components.
    ///
    /// For example, to represent `20:10:05.128-07:00`:
    ///
    ///     let time = PostgresTimeWithTimeZone(hour: 20,
    ///                                         minute: 10,
    ///                                         second: 05,
    ///                                         nanosecond: 128000000,
    ///                                         timeZone: TimeZone(secondsFromGMT: -7 * 60 * 60)!)
    ///
    /// The specified time zone must have a fixed offset from UTC/GMT; its offset must not change
    /// due to daylight savings time.  (This requirement is a consequence of `TIME WITH TIME ZONE`
    /// values not having the year, month, and day components required to determine whether daylight
    /// savings time is in effect.)
    ///
    /// - Parameters:
    ///   - hour: the hour value
    ///   - minute: the minute value
    ///   - second: the second value
    ///   - nanosecond: the nanosecond value
    ///   - timeZone: the time zone in which to interpret these components
    public init?(hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0,
                 timeZone: TimeZone) {
        
        #if os(Linux)  // temporary workaround for https://bugs.swift.org/browse/SR-10516
            guard timeZone.nextDaylightSavingTimeTransition == nil ||
                timeZone.nextDaylightSavingTimeTransition?.timeIntervalSinceReferenceDate == 0.0 else {
                    
                Postgres.logger.info(
                    "timeZone must not observe daylight savings time; use TimeZone(secondsFromGMT:)")
                return nil
            }
        #else
            guard timeZone.nextDaylightSavingTimeTransition == nil else {
                Postgres.logger.info(
                    "timeZone must not observe daylight savings time; use TimeZone(secondsFromGMT:)")
                return nil
            }
        #endif
        
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        dc.timeZone = timeZone
        
        guard dc.isValidDate(in: Postgres.enUsPosixUtcCalendar) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// Creates a `PostgresTimeWithTimeZone` by interpreting a `Date` in a specified time zone to
    /// obtain the hour, minute, second, and fractional second components, discarding the year,
    /// month, and day components.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// The specified time zone must have a fixed offset from UTC/GMT; its offset must not change
    /// due to daylight savings time.  (This requirement is a consequence of `TIME WITH TIME ZONE`
    /// values not having the year, month, and day components required to determine whether daylight
    /// savings time is in effect.)
    ///
    /// - Parameters:
    ///   - date: the moment in time
    ///   - timeZone: the time zone in which to interpret that moment
    public init?(date: Date, in timeZone: TimeZone) {
        
        let dc = Postgres.enUsPosixUtcCalendar.dateComponents(in: timeZone, from: date)
        
        guard let hour = dc.hour,
            let minute = dc.minute,
            let second = dc.second,
            let nanosecond = dc.nanosecond else {
                // Can't happen.
                preconditionFailure("Invalid date components from \(date): \(dc)")
        }
        
        self.init(hour: hour,
                  minute: minute,
                  second: second,
                  nanosecond: nanosecond,
                  timeZone: timeZone)
    }
    
    /// Creates a `PostgresTimeWithTimeZone` from a string.
    ///
    /// The string must conform to the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSSxxxxx`.  For example, `20:10:05.128-07:00`.
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        var string = string.trimmingCharacters(in: [ " " ])
        
        var timeZone: TimeZone
        
        if string.hasSuffix("Z") {
            timeZone = TimeZone(secondsFromGMT: 0)!
            string.removeLast()
        } else {
            guard let offsetSignIndex = string.lastIndex(where: { $0 == "+" || $0 == "-" }) else {
                return nil
            }
            
            var offset = (string[offsetSignIndex] == "+") ? 1 : -1
            var timeZoneString = string[string.index(after: offsetSignIndex)...].filter { $0 != ":" }
            string.removeSubrange(offsetSignIndex...)
            
            if timeZoneString.count == 1 || timeZoneString.count == 3 {
                timeZoneString = "0" + timeZoneString
            }
            
            switch timeZoneString.count {
                
            case 4:
                let i2 = timeZoneString.index(timeZoneString.startIndex, offsetBy: 2)
                guard let offsetHH = Int(timeZoneString[..<i2]) else { return nil }
                guard let offsetMM = Int(timeZoneString[i2...]) else { return nil }
                offset *= 3600 * offsetHH + 60 * offsetMM
                
            case 2:
                guard let offsetHH = Int(timeZoneString) else { return nil }
                offset *= 3600 * offsetHH
                
            default:
                return nil
            }
            
            timeZone = TimeZone(secondsFromGMT: offset)!
        }
        
        guard var date = PostgresTimeWithTimeZone.formatter.date(from: string) else {
            return nil
        }
        
        date = date - TimeInterval(exactly: timeZone.secondsFromGMT())!
        
        self.init(date: date, in: timeZone)
    }
    
    /// A `DateComponents` for this `PostgresTimeWithTimeZone`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    /// - `timeZone`
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }

    /// A `Date` for this `PostgresTimeWithTimeZone`, created by setting the year component to 2000
    /// and the month and day components to 1.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the moment in time
    public var date: Date {
        return inner.date
    }
    
    /// The time zone in which this `PostgresTimeWithTimeZone` was specified.
    public var timeZone: TimeZone {
        return inner.dateComponents.timeZone!
    }
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresTimeWithTimeZone`.
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `PostgresTimeWithTimeZone`.
    ///
    /// Equivalent to `String(describing: postgresValue)`.
    public var description: String {
        return String(describing: postgresValue)
    }
    
    
    //
    // MARK: Implementation
    //
    
    /// Formats Postgres `TIME WITH TIME ZONE` values (excluding the terminal time zone part).
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "HH:mm:ss.SSS"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = Postgres.utcTimeZone
        return df
    }()
    
    // Inner class to allow the struct to be immutable yet have lazily instantiated properties.
    private let inner: Inner
    
    private class Inner {
        
        fileprivate init(dateComponents: DateComponents) {
            self.dateComponents = dateComponents
        }
        
        fileprivate let dateComponents: DateComponents
        
        fileprivate lazy var date: Date = {
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.year = 2000
            dc.month = 1
            dc.day = 1
            return Postgres.enUsPosixUtcCalendar.date(from: dc)! // validated components on the way in
        }()
        
        fileprivate lazy var postgresValue: PostgresValue = {
            
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.timeZone = Postgres.utcTimeZone // since formatter assumes UTC; timeZone handled below
            dc.year = 2000
            dc.month = 1
            dc.day = 1
            let d = Postgres.enUsPosixUtcCalendar.date(from: dc)!
            let s = PostgresTimeWithTimeZone.formatter.string(from: d)
            
            var offset = dateComponents.timeZone!.secondsFromGMT()
            var timeZoneString = (offset < 0) ? "-" : "+"
            offset = abs(offset)
            let offsetHH = offset / 3600
            let offsetMM = (offset % 3600) / 60
            timeZoneString += String(format: "%02d:%02d", offsetHH, offsetMM)
            
            return PostgresValue(s + timeZoneString)
        }()
    }
}

public extension Date {
    
    /// Creates a `PostgresTimeWithTimeZone` by interpreting this `Date` in a specified time zone.
    ///
    /// Equivalent to `PostgresTimeWithTimeZone(date: self, in: timeZone)`.
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the `PostgresTimeWithTimeZone`
    func postgresTimeWithTimeZone(in timeZone: TimeZone) -> PostgresTimeWithTimeZone? {
        return PostgresTimeWithTimeZone(date: self, in: timeZone)
    }
}

// EOF
