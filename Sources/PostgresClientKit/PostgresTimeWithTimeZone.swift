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
public struct PostgresTimeWithTimeZone:
    PostgresValueConvertible, Equatable, CustomStringConvertible {
    
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

        if !ISO8601.timeZoneHasFixedOffsetFromUTC(timeZone) {
            Postgres.logger.info(
                "timeZone must not observe daylight savings time; use TimeZone(secondsFromGMT:)")
            return nil
        }
        
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        dc.timeZone = timeZone
        
        guard let _ = ISO8601.validateDateComponents(dc) else {
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
        
        let dc = ISO8601.dateComponents(from: date, in: timeZone)
        
        var dc2 = DateComponents()
        dc2.hour = dc.hour
        dc2.minute = dc.minute
        dc2.second = dc.second
        dc2.nanosecond = dc.nanosecond
        dc2.timeZone = timeZone
        
        inner = Inner(dateComponents: dc2)
    }
    
    /// Creates a `PostgresTimeWithTimeZone` from a string.
    ///
    /// The string must conform to either the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `HH:mm:ss.SSSxxxxx` (for example, `20:10:05.128-07:00`) or
    /// `HH:mm:ssxxxxx` (for example, `20:10:05-07:00`).
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        guard let dc = ISO8601.parseTimeWithTimeZone(string) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
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
    // MARK: Equatable
    //
    
    /// True if `lhs.postgresValue == rhs.postgresValue`.
    public static func == (lhs: PostgresTimeWithTimeZone, rhs: PostgresTimeWithTimeZone) -> Bool {
        return lhs.postgresValue == rhs.postgresValue
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
    
    // Inner class to allow the struct to be immutable yet have lazily instantiated properties.
    private let inner: Inner
    
    private class Inner {
        
        fileprivate init(dateComponents: DateComponents) {
            self.dateComponents = dateComponents
        }
        
        fileprivate let dateComponents: DateComponents
        
        fileprivate lazy var date: Date = {
            var dc = dateComponents
            dc.year = 2000
            dc.month = 1
            dc.day = 1
            return ISO8601.unvalidatedDate(from: dc) // validated on the way in
        }()
        
        fileprivate lazy var postgresValue = PostgresValue(ISO8601.formatTimeWithTimeZone(
            validatedDateComponents: dateComponents)) // validated on the way in
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
