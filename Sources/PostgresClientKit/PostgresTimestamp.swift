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
/// Although `Date` supports 9 digits in the fractional seconds component (nanosecond resolution),
/// Postgres does not support more than 6 digits (microsecond resolution).  Additionally, due
/// to [a bug](https://stackoverflow.com/questions/23684727/nsdateformatter-milliseconds-bug)
/// in the Foundation `DateFormatter` class, `PostgresTimestamp` preserves only 3 digits
/// (millisecond resolution) in converting to and from string representations.
public struct PostgresTimestamp: PostgresValueConvertible, CustomStringConvertible {
    
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
        
        guard dc.isValidDate(in: Postgres.enUsPosixUtcCalendar) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    public init(date: Date, in timeZone: TimeZone) {
        
        let dc = Postgres.enUsPosixUtcCalendar.dateComponents(in: timeZone, from: date)
        
        guard let year = dc.year,
            let month = dc.month,
            let day = dc.day,
            let hour = dc.hour,
            let minute = dc.minute,
            let second = dc.second,
            let nanosecond = dc.nanosecond else {
                // Can't happen.
                preconditionFailure("Invalid date components from \(date): \(dc)")
        }
        
        self.init(year: year,
                  month: month,
                  day: day,
                  hour: hour,
                  minute: minute,
                  second: second,
                  nanosecond: nanosecond)!
    }
    
    public init?(_ string: String) {
        
        guard let date = PostgresTimestamp.formatter.date(from: string) else {
            return nil
        }
        
        self.init(date: date, in: PostgresTimestamp.formatter.timeZone)
    }
    
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }

    public func date(in timeZone: TimeZone) -> Date {
        var dc = inner.dateComponents
        dc.calendar = Postgres.enUsPosixUtcCalendar
        dc.timeZone = timeZone
        return Postgres.enUsPosixUtcCalendar.date(from: dc)! // validated components on the way in
    }
    
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    public var description: String {
        return String(describing: postgresValue)
    }

    /// Formats Postgres `TIMESTAMP` values.
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
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
        
        fileprivate lazy var postgresValue: PostgresValue = {
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.timeZone = Postgres.utcTimeZone
            let d = Postgres.enUsPosixUtcCalendar.date(from: dc)!
            let s = PostgresTimestamp.formatter.string(from: d)
            return PostgresValue(s)
        }()
    }
}

public extension Date {
    
    func postgresTimestamp(in timeZone: TimeZone) -> PostgresTimestamp {
        return PostgresTimestamp(date: self, in: timeZone)
    }
}

// EOF
