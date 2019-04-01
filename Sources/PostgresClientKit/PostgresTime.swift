//
//  PostgresTime.swift
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

/// Represents a Postgres `TIME` value, which consists of the following components:
///
/// - hour
/// - minute
/// - seconds (and fractional seconds)
///
/// For example, `16:25:19.365`.
public struct PostgresTime: ValueConvertible, CustomStringConvertible {
    
    public init?(hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0) {
        
        var dc = DateComponents()
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
                  nanosecond: nanosecond)!
    }
    
    public init?(_ string: String) {
        
        guard let date = PostgresTime.formatter.date(from: string) else {
            return nil
        }
        
        self.init(date: date, in: PostgresTime.formatter.timeZone)
    }
    
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }
    
    public func date(in timeZone: TimeZone) -> Date {
        var dc = inner.dateComponents
        dc.calendar = Postgres.enUsPosixUtcCalendar
        dc.timeZone = timeZone
        dc.year = 2000
        dc.month = 1
        dc.day = 1
        return Postgres.enUsPosixUtcCalendar.date(from: dc)! // validated components on the way in
    }
    
    public var postgresValue: Value {
        return inner.postgresValue
    }
    
    public var description: String {
        return String(describing: postgresValue)
    }
    
    /// Formats Postgres `TIME` values.
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
        
        fileprivate lazy var postgresValue: Value = {
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.timeZone = Postgres.utcTimeZone
            let d = Postgres.enUsPosixUtcCalendar.date(from: dc)!
            let s = PostgresTime.formatter.string(from: d)
            return Value(s)
        }()
    }
}

public extension Date {
    
    func postgresTime(in timeZone: TimeZone) -> PostgresTime {
        return PostgresTime(date: self, in: timeZone)
    }
}

// EOF
