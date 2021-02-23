//
//  PostgresTimestampWithTimeZone.swift
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

/// Represents a Postgres `TIMESTAMP WITH TIME ZONE` value, which consists of the following
/// components:
///
/// - year
/// - month
/// - day
/// - hour
/// - minute
/// - seconds (and fractional seconds)
/// - time zone (expressed as an offset from UTC/GMT)
///
/// For example, `2019-03-14 16:25:19.365+00:00`.
///
/// Like Postgres itself, PostgresClientKit normalizes `TIMESTAMP WITH TIME ZONE` values by
/// converting them to UTC/GMT.  The values are thus simply moments in time and representable
/// by Foundation `Date` instances.
///
/// Like Foundation `DateComponents`, PostgresClientKit records fractional seconds in nanoseconds.
/// However, [due to a bug](https://stackoverflow.com/questions/23684727) in the Foundation
/// `DateFormatter` class, only 3 fractional digits are preserved (millisecond resolution) in
/// values sent to and received from the Postgres server.
public struct PostgresTimestampWithTimeZone:
    PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresTimestampWithTimeZone` from components.
    ///
    /// For example, to represent `2019-03-14 16:25:19.365+00:00`:
    ///
    ///     let moment = PostgresTimestampWithTimeZone(year: 2019,
    ///                                                month: 3,
    ///                                                day: 14,
    ///                                                hour: 16,
    ///                                                minute: 25,
    ///                                                second: 19,
    ///                                                nanosecond: 365000000,
    ///                                                timeZone: TimeZone(secondsFromGMT: 0)!)
    ///
    /// - Parameters:
    ///   - year: the year value
    ///   - month: the month value (1 for January, 2 for February, and so on)
    ///   - day: the day value
    ///   - hour: the hour value
    ///   - minute: the minute value
    ///   - second: the second value
    ///   - nanosecond: the nanosecond value
    ///   - timeZone: the time zone in which to interpret these components
    public init?(year: Int,
                 month: Int,
                 day: Int,
                 hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0,
                 timeZone: TimeZone) {
        
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        
        guard let date = ISO8601.validateDateComponents(dc, in: timeZone)?.date else {
            return nil
        }
        
        self.init(date: date)
    }

    /// Creates a `PostgresTimestampWithTimeZone` from a `Date`.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameter date: the moment in time
    public init(date: Date) {
        inner = Inner(date: date)
    }
    
    /// Creates a `PostgresTimestampWithTimeZone` from a string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSSxxxxx` (for example, `2019-03-14 16:25:19.365+00:00`) or
    /// `yyyy-MM-dd HH:mm:ssxxxxx` (for example, `2019-03-14 16:25:19+00:00`).
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        guard let date = ISO8601.parseTimestampWithTimeZone(string) else {
            return nil
        }
        
        self.init(date: date)
    }
    
    /// A `DateComponents` for this `PostgresTimestampWithTimeZone`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `calendar`
    /// - `year`
    /// - `month`
    /// - `day`
    /// - `hour`
    /// - `minute`
    /// - `second`
    /// - `nanosecond`
    /// - `timeZone`
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }
    
    /// A `Date` for this `PostgresTimestampWithTimeZone`.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    public var date: Date {
        return inner.date
    }
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresTimestampWithTimeZone`.
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    
    //
    // MARK: Equatable
    //
    
    /// True if `lhs.postgresValue == rhs.postgresValue`.
    public static func == (lhs: PostgresTimestampWithTimeZone,
                           rhs: PostgresTimestampWithTimeZone) -> Bool {
        return lhs.postgresValue == rhs.postgresValue
    }

    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `PostgresTimestampWithTimeZone`.
    ///
    /// Equivalent to `String(describing: postgresValue)`.
    public var description: String {
        return String(describing: postgresValue)
    }
    
    
    //
    // MARK: Implementation
    //

    // Inner class to allow the struct to be immutable yet have lazily instantiated properties.
    private let inner: Inner
    
    private class Inner {
        
        fileprivate init(date: Date) {
            self.date = date
        }
        
        fileprivate let date: Date
        
        fileprivate lazy var dateComponents : DateComponents = {
            var dc = ISO8601.dateComponents(from: date, in: ISO8601.utcTimeZone)
            dc.calendar = ISO8601.enUsPosixUtcCalendar // slow but required for backward API compatibility
            dc.timeZone = ISO8601.utcTimeZone
            return dc
        }()
        
        fileprivate lazy var postgresValue =
            PostgresValue(ISO8601.formatTimestampWithTimeZone(date: date))
    }
}

public extension Date {
    
    /// A `PostgresTimestampWithTimeZone` for this `Date`.
    ///
    /// Equivalent to `PostgresTimestampWithTimeZone(date: self)`.
    var postgresTimestampWithTimeZone: PostgresTimestampWithTimeZone {
        return PostgresTimestampWithTimeZone(date: self)
    }
}

// EOF
