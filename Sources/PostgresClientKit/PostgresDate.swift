//
//  PostgresDate.swift
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

/// Represents a Postgres `DATE` value, which consists of the following components:
///
/// - year
/// - month
/// - day
///
/// For example, `2019-03-14`.
public struct PostgresDate: ValueConvertible, CustomStringConvertible {
    
    public init?(year: Int,
                 month: Int,
                 day: Int) {
        
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        
        guard dc.isValidDate(in: Postgres.enUsPosixUtcCalendar) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    public init(date: Date, in timeZone: TimeZone) {
        
        let dc = Postgres.enUsPosixUtcCalendar.dateComponents(in: timeZone, from: date)
        
        guard let year = dc.year,
            let month = dc.month,
            let day = dc.day else {
                // Can't happen.
                preconditionFailure("Invalid date components from \(date): \(dc)")
        }
        
        self.init(year: year,
                  month: month,
                  day: day)!

    }
    
    public init?(_ string: String) {
        
        guard let date = PostgresDate.formatter.date(from: string) else {
            return nil
        }
        
        self.init(date: date, in: PostgresDate.formatter.timeZone)
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
    
    public var postgresValue: Value {
        return inner.postgresValue
    }
    
    public var description: String {
        return String(describing: postgresValue)
    }

    /// Formats Postgres `DATE` values.
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Postgres.enUsPosixUtcCalendar
        df.dateFormat = "yyyy-MM-dd"
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
            let s = PostgresDate.formatter.string(from: d)
            return Value(s)
        }()
    }
}

public extension Date {
    
    func postgresDate(in timeZone: TimeZone) -> PostgresDate {
        return PostgresDate(date: self, in: timeZone)
    }
}

// EOF
