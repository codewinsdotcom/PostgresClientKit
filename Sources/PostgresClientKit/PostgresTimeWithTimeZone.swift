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
/// - time zone (expressed as a fixed offset from UTC/GMT)
///
/// For example, `16:25:19.365-07`.
///
/// Unlike `TIMESTAMP WITH TIME ZONE`, a `TIME WITH TIME ZONE` value is not normalized to UTC/GMT;
/// the time zone in which it is specified is preserved.
///
/// Although `Date` supports 9 digits in the fractional seconds component (nanosecond resolution),
/// Postgres does not support more than 6 digits (microsecond resolution).  Additionally, due
/// to [a bug](https://stackoverflow.com/questions/23684727/nsdateformatter-milliseconds-bug)
/// in the Foundation `DateFormatter` class, `PostgresTimeWithTimeZone` preserves only 3 digits
/// (millisecond resolution) in converting to and from string representations.
public struct PostgresTimeWithTimeZone: ValueConvertible, CustomStringConvertible {
    
    public init?(hour: Int,
                 minute: Int,
                 second: Int,
                 nanosecond: Int = 0,
                 timeZone: TimeZone) {
        
        guard timeZone.nextDaylightSavingTimeTransition == nil else {
            Postgres.logger.info(
                "timeZone must not adopt daylight savings time; use TimeZone(secondsFromGMT:)")
            return nil
        }
        
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
    
    public var dateComponents: DateComponents {
        return inner.dateComponents
    }

    public var date: Date {
        return inner.date
    }
    
    public var timeZone: TimeZone {
        return inner.dateComponents.timeZone!
    }
    
    public var postgresValue: Value {
        return inner.postgresValue
    }
    
    public var description: String {
        return String(describing: postgresValue)
    }

    /// Formats Postgres `TIME WITH TIME ZONE` values.
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
        
        fileprivate lazy var postgresValue: Value = {
            
            var dc = dateComponents
            dc.calendar = Postgres.enUsPosixUtcCalendar
            dc.timeZone = Postgres.utcTimeZone // since formatter assumes UTC; timeZone handled below
            let d = Postgres.enUsPosixUtcCalendar.date(from: dc)!
            let s = PostgresTimeWithTimeZone.formatter.string(from: d)
            
            var offset = dateComponents.timeZone!.secondsFromGMT()
            var timeZoneString = (offset < 0) ? "-" : "+"
            offset = abs(offset)
            let offsetHH = offset / 3600
            let offsetMM = (offset % 3600) / 60
            timeZoneString += String(format: "%02d:%02d", offsetHH, offsetMM)
            
            return Value(s + timeZoneString)
        }()
    }
}

public extension Date {
    
    func postgresTimeWithTimeZone(in timeZone: TimeZone) -> PostgresTimeWithTimeZone? {
        return PostgresTimeWithTimeZone(date: self, in: timeZone)
    }
}

// EOF
