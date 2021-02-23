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
public struct PostgresDate: PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresDate` from components.
    ///
    /// For example, to represent `2019-03-14`:
    ///
    ///     let date = PostgresDate(year: 2019,
    ///                             month: 3,
    ///                             day: 14)
    ///
    /// - Parameters:
    ///   - year: the year value
    ///   - month: the month value (1 for January, 2 for February, and so on)
    ///   - day: the day value
    public init?(year: Int,
                 month: Int,
                 day: Int) {
        
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        
        guard let _ = ISO8601.validateDateComponents(dc, in: ISO8601.utcTimeZone) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// Creates a `PostgresDate` by interpreting a `Date` in a specified time zone to obtain the
    /// year, month, and day components, and discarding the hour, minute, second, and fractional
    /// second components.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameters:
    ///   - date: the moment in time
    ///   - timeZone: the time zone in which to interpret that moment
    public init(date: Date, in timeZone: TimeZone) {
        
        let dc = ISO8601.dateComponents(from: date, in: timeZone)
        
        var dc2 = DateComponents()
        dc2.year = dc.year
        dc2.month = dc.month
        dc2.day = dc.day
        
        inner = Inner(dateComponents: dc2)
    }
    
    /// Creates a `PostgresDate` from a string.
    ///
    /// The string must conform to the [date format pattern](
    /// http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)
    /// `yyyy-MM-dd`.  For example, `2019-03-14`.
    ///
    /// - Parameter string: the string
    public init?(_ string: String) {
        
        guard let dc = ISO8601.parseDate(string) else {
            return nil
        }
        
        inner = Inner(dateComponents: dc)
    }
    
    /// A `DateComponents` value for this `PostgresDate`.
    ///
    /// The returned value has the following components set:
    ///
    /// - `year`
    /// - `month`
    /// - `day`
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }
    
    /// Creates a `Date` by interpreting this `PostgresDate` in a specified time zone, setting the
    /// hour, minute, second, and fractional second components to 0.
    ///
    /// (Foundation `Date` instances represent moments in time, not *(year, month, day)* tuples.)
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the moment in time
    public func date(in timeZone: TimeZone) -> Date {
        var dc = inner.dateComponents
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        dc.nanosecond = 0
        return ISO8601.unvalidatedDate(from: dc, in: timeZone) // validated on the way in
    }
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresDate`.
    public var postgresValue: PostgresValue {
        return inner.postgresValue
    }
    
    
    //
    // MARK: Equatable
    //
    
    /// True if `lhs.postgresValue == rhs.postgresValue`.
    public static func == (lhs: PostgresDate, rhs: PostgresDate) -> Bool {
        return lhs.postgresValue == rhs.postgresValue
    }

    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `PostgresDate`.
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
        
        fileprivate lazy var postgresValue = PostgresValue(ISO8601.formatDate(
            validatedDateComponents: dateComponents)) // validated on the way in
    }
}

public extension Date {
    
    /// Creates a `PostgresDate` by interpreting this `Date` in a specified time zone.
    ///
    /// Equivalent to `PostgresDate(date: self, in: timeZone)`.
    ///
    /// - Parameter timeZone: the time zone
    /// - Returns: the `PostgresDate`
    func postgresDate(in timeZone: TimeZone) -> PostgresDate {
        return PostgresDate(date: self, in: timeZone)
    }
}

// EOF
