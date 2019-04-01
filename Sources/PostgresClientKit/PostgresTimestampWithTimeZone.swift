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
/// - time zone (expressed as a fixed offset from UTC/GMT)
///
/// For example, `2019-03-14 16:25:19.365-07`.
///
/// Like Postgres itself, PostgresClientKit normalizes `TIMESTAMP WITH TIME ZONE` values by
/// converting them to UTC/GMT.  The values are thus simply moments in time and representable
/// by Foundation `Date` instances.
///
/// Although `Date` supports 9 digits in the fractional seconds component (nanosecond resolution),
/// Postgres does not support more than 6 digits (microsecond resolution).  Additionally, due
/// to [a bug](https://stackoverflow.com/questions/23684727/nsdateformatter-milliseconds-bug)
/// in the Foundation `DateFormatter` class, `PostgresTimestampWithTimeZone` preserves only 3
/// digits (millisecond resolution) in converting to and from string representations.
public struct PostgresTimestampWithTimeZone: ValueConvertible, CustomStringConvertible {
    
    public init?(year: Int,
                 month: Int,
                 day: Int,
                 hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0,
                 timeZone: TimeZone) {
        
        var dc = DateComponents()
        dc.calendar = Postgres.enUsPosixUtcCalendar
        dc.year = year
        dc.month = month
        dc.day = day
        dc.hour = hour
        dc.minute = minute
        dc.second = second
        dc.nanosecond = nanosecond
        dc.timeZone = timeZone
        
        guard dc.isValidDate, let date = dc.date else {
            return nil
        }
        
        inner = Inner(date: date)
    }

    public init(date: Date) {
        inner = Inner(date: date)
    }
    
    public init?(_ string: String) {
        
        guard let date = PostgresTimestampWithTimeZone.formatter.date(from: string) else {
            return nil
        }
        
        inner = Inner(date: date)
    }
    
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }
    
    public var date: Date {
        return inner.date
    }
    
    public var postgresValue: Value {
        return inner.postgresValue
    }
    
    public var description: String {
        return String(describing: postgresValue)
    }

    /// Formats Postgres `TIMESTAMP WITH TIME ZONE` values.
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSxxxxx"
        df.locale = Postgres.enUsPosixLocale
        df.timeZone = Postgres.utcTimeZone
        return df
    }()

    // Inner class to allow the struct to be immutable yet have lazily instantiated properties.
    private let inner: Inner
    
    private class Inner {
        
        fileprivate init(date: Date) {
            self.date = date
        }
        
        fileprivate let date: Date
        
        fileprivate lazy var dateComponents: DateComponents =
            Postgres.enUsPosixUtcCalendar.dateComponents([
                .calendar,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .nanosecond,
                .timeZone], from: date)
        
        fileprivate lazy var postgresValue: Value = Value(
            PostgresTimestampWithTimeZone.formatter.string(from: date))
    }
}

public extension Date {
    
    var postgresTimestampWithTimeZone: PostgresTimestampWithTimeZone {
        return PostgresTimestampWithTimeZone(date: self)
    }
}

// EOF
