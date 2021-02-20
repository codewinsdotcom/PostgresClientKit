//
//  PostgresTimestamp.swift
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

/// Represents a Postgres `TIMESTAMP` value, which consists of the following components:
///
/// - year
/// - month
/// - day
/// - hour
/// - minute
/// - seconds (and fractional seconds)
///
/// For example, `2019-03-14 16:25:19.365`.
///
/// Unlike `TIMESTAMP WITH TIME ZONE`, a `TIMESTAMP` value does not have a time zone component.
/// Consequently, it does not, by itself, represent a specific moment in time.  For example, if
/// two persons in different time zones wished to schedule a telephone call, the call's starting
/// time could not be unambiguously recorded by a `TIMESTAMP` value because it would not indicate
/// in which time zone the date and time components are to be interpreted.
///
/// (For this reason, `TIMESTAMP WITH TIME ZONE` is often a more useful data type.  See
/// `PostgresTimestampWithTimeZone`.)
///
/// Like Foundation `DateComponents`, PostgresClientKit records fractional seconds in nanoseconds.
/// However, [due to a bug](https://stackoverflow.com/questions/23684727) in the Foundation
/// `DateFormatter` class, only 3 fractional digits are preserved (millisecond resolution) in
/// values sent to and received from the Postgres server.
public struct PostgresTimestamp: PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresTimestamp` from components.
    ///
    /// For example, to represent `2019-03-14 16:25:19.365`:
    ///
    ///     let timestamp = PostgresTimestamp(year: 2019,
    ///                                       month: 3,
    ///                                       day: 14,
    ///                                       hour: 16,
    ///                                       minute: 25,
    ///                                       second: 19,
    ///                                       nanosecond: 365000000)
    ///
    /// - Parameters:
    ///   - year: the year value
    ///   - month: the month value (1 for January, 2 for February, and so on)
    ///   - day: the day value
    ///   - hour: the hour value
    ///   - minute: the minute value
    ///   - second: the second value
    ///   - nanosecond: the nanosecond value
    public init?(year: Int,
                 month: Int,
                 day: Int,
                 hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0) {
        
        // TIMESTAMP has no intrinsic time zone, so don't set the timeZone component of
        // DateComponents.  Since Calendar also has a timeZone property, don't set the
        // calendar component of DateComponents either.
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        
        guard let _ = ISO8601.validateDateComponents(dc, in: ISO8601.utcTimeZone) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// Creates a `PostgresTimestamp` by interpreting a `Date` in a specified time zone.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameters:
    ///   - date: the moment in time
    ///   - timeZone: the time zone in which to interpret that moment
    public init(date: Date, in timeZone: TimeZone) {
        let dc = ISO8601.dateComponents(from: date, in: timeZone)
        inner = Inner(dateComponents: dc)
    }
    
    /// Creates a `PostgresTimestamp` from a string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd HH:mm:ss.SSS` (for example, `2019-03-14 16:25:19.365`) or
    /// `yyyy-MM-dd HH:mm:ss` (for example, `2019-03-14 16:25:19`) .
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        guard let dc = ISO8601.parseTimestamp(string) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// A `DateComponents` for this `PostgresTimestamp`.
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
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }

    /// Creates a `Date` by interpreting this `PostgresTimestamp` in a specified time zone.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the moment in time
    public func date(in timeZone: TimeZone) -> Date {
        return ISO8601.unvalidatedDate(from: inner.dateComponents, in: timeZone) // validated on the way in
    }
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresTimestamp`.
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    
    //
    // MARK: Equatable
    //
    
    /// True if `lhs.postgresValue == rhs.postgresValue`.
    public static func == (lhs: PostgresTimestamp, rhs: PostgresTimestamp) -> Bool {
        return lhs.postgresValue == rhs.postgresValue
    }

    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `PostgresTimestamp`.
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
        
        fileprivate init(dateComponents: DateComponents) {
            self.dateComponents = dateComponents
        }
        
        fileprivate let dateComponents: DateComponents
        
        fileprivate lazy var postgresValue = PostgresValue(ISO8601.formatTimestamp(
            validatedDateComponents: dateComponents)) // validated on the way in
    }
}

public extension Date {
    
    /// Creates a `PostgresTimestamp` by interpreting this `Date` in a specified time zone.
    ///
    /// Equivalent to `PostgresTimestamp(date: self, in: timeZone)`.
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the `PostgresTimestamp`
    func postgresTimestamp(in timeZone: TimeZone) -> PostgresTimestamp {
        return PostgresTimestamp(date: self, in: timeZone)
    }
}

// EOF
