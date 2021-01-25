//
//  Analysis.swift
//  PostgresClientKitTests
//
//  Created by David Pitfield on 1/24/21.
//

import Foundation
@testable import PostgresClientKit
import XCTest

class Analysis: XCTestCase {
    
    func testPostgresTimestampWithTimeZone() throws {

        // Results (My Mac, release build):
        //
        // 66.614 us yyyy-MM-dd HH:mm:ss.SSSxxxxx formatter.date(from:) (10000 iterations) 2019-01-02 11:04:05 +0000
        // 66.271 us yyyy-MM-dd HH:mm:ssxxxxx formatter.date(from:)     (10000 iterations) 2019-01-02 11:04:05 +0000
        //
        // Conclusions:
        // - DateFormatter.date(from:) accounts for nearly all the elapsed time in the existing
        //   implementation
        
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSxxxxx"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()

        /// Alternative formattter for parsing Postgres `TIMESTAMP WITH TIME ZONE` values.
        let formatter2: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ssxxxxx"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()

        try time("yyyy-MM-dd HH:mm:ss.SSSxxxxx formatter.date(from:)") {
            formatter.date(from: "2019-01-02 03:04:05.365-08")!
        }
        
        try time("yyyy-MM-dd HH:mm:ssxxxxx formatter.date(from:)") {
            formatter2.date(from: "2019-01-02 03:04:05-08")!
        }
    }

    func testPostgresTimestamp() throws {

        // Results (My Mac, release build):
        //
        // 56.440 us yyyy-MM-dd HH:mm:ss.SSS formatter.date(from:)      (10000 iterations) 2019-01-02 03:04:05 +0000
        // 49.291 us yyyy-MM-dd HH:mm:ss formatter.date(from:)          (10000 iterations) 2019-01-02 03:04:05 +0000
        // 21.453 us Calendar.dateComponents(in:from:)                  (10000 iterations) calendar: gregorian (fixed) timeZone: GMT (fixed) era: 1 year: 2019 month: 1 day: 2 hour: 3 minute: 4 second: 5 nanosecond: 365000009 weekday: 4 weekdayOrdinal: 1 quarter: 0 weekOfMonth: 1 weekOfYear: 1 yearForWeekOfYear: 2019 isLeapMonth: false
        //  0.466 us DateComponents() + setters                         (1000000 iterations) year: 2019 month: 1 day: 2 hour: 3 minute: 4 second: 5 nanosecond: 365000009 isLeapMonth: false
        // 29.385 us Postgres.isValidDate()                             (10000 iterations) true
        // 11.603 us Set calendar + timeZone of DateComponents          (10000 iterations) calendar: gregorian (fixed) timeZone: America/Los_Angeles (current) era: 1 year: 2019 month: 1 day: 2 hour: 3 minute: 4 second: 5 nanosecond: 365000009 weekday: 4 weekdayOrdinal: 1 quarter: 0 weekOfMonth: 1 weekOfYear: 1 yearForWeekOfYear: 2019 isLeapMonth: false
        // 35.300 us Postgres.enUsPosixUtcCalendar.date(from:)          (10000 iterations) 2019-01-02 11:04:05 +0000
        //
        // Conclusions:
        // - the above steps account for nearly all the elapsed time in the existing implementation
        
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()

        /// Alternative formattter for parsing Postgres `TIMESTAMP WITH TIME ZONE` values.
        let formatter2: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()

        try time("yyyy-MM-dd HH:mm:ss.SSS formatter.date(from:)") {
            formatter.date(from: "2019-01-02 03:04:05.365")!
        }
        
        try time("yyyy-MM-dd HH:mm:ss formatter.date(from:)") {
            formatter2.date(from: "2019-01-02 03:04:05")!
        }
        
        let utc = Postgres.utcTimeZone
        let d = formatter.date(from: "2019-01-02 03:04:05.365")!
        
        
        try time("Calendar.dateComponents(in:from:)") {
            
            Postgres.enUsPosixUtcCalendar.dateComponents(in: utc, from: d)
        }
        
        let dc = Postgres.enUsPosixUtcCalendar.dateComponents(in: utc, from: d)
        
        guard let year = dc.year,
            let month = dc.month,
            let day = dc.day,
            let hour = dc.hour,
            let minute = dc.minute,
            let second = dc.second,
            let nanosecond = dc.nanosecond else {
                // Can't happen.
                preconditionFailure("Invalid date components")
        }
        
        try time("DateComponents() + setters") {
            var dc = DateComponents()
            dc.year = year
            dc.month = month
            dc.day = day
            dc.hour = hour
            dc.minute = minute
            dc.second = second
            dc.nanosecond = nanosecond
            return dc
        }
        
        var dc2 = DateComponents()
        dc2.year = year
        dc2.month = month
        dc2.day = day
        dc2.hour = hour
        dc2.minute = minute
        dc2.second = second
        dc2.nanosecond = nanosecond
        
        try time("Postgres.isValidDate()") {
            Postgres.isValidDate(dc)
        }
        
        let tz = TimeZone.current
        
        try time("Set calendar + timeZone of DateComponents") {
            var dc3 = dc
            dc3.calendar = Postgres.enUsPosixUtcCalendar
            dc3.timeZone = tz
            return dc3
        }

        var dc3 = dc
        dc3.calendar = Postgres.enUsPosixUtcCalendar
        dc3.timeZone = tz

        try time("Postgres.enUsPosixUtcCalendar.date(from:)") {
            Postgres.enUsPosixUtcCalendar.date(from: dc3)!
        }
    }
    
    
    let semaphore = DispatchSemaphore(value: 1)
    let lock = NSLock()
    var counter = 0
    
    func testSynchronizationPerformance() throws {
        
        // Results (My Mac, release build):
        //
        // 0.014 us DispatchSemaphore                                  (10000000 iterations) 1
        // 0.023 us NSLock                                             (10000000 iterations) 11111002
        //
        // Conclusions:
        // - DispatchSemaphore is nearly twice as fast as NSLock for low-contention conditions
        
        try time("DispatchSemaphore") {
            semaphore.wait()
            defer { semaphore.signal() }
            counter += 1
            return counter
        }
        
        try time("NSLock") {
            lock.lock()
            defer { lock.unlock() }
            counter += 1
            return counter
        }
    }
    
    
    func testThreadDictionary() throws {
        
        // Results (My Mac, release build):
        //
        // 0.608 us ThreadDictionary                                   (1000000 iterations) 1
        //
        // Conclusions:
        // - ThreadDictionary is cheap but not free; use judiciously
        
//        var counter = 0

        // time(...) overflows, assume instance property is nearly instantaneous
//        try time("Instance property") {
//            counter &+= 1
//            return counter
//        }
        
        try time("ThreadDictionary") {
            let threadDictionary = Thread.current.threadDictionary
            var counter = (threadDictionary["counter"] as! Int?) ?? 0
            counter += 1
            threadDictionary["counter"] = counter
            return counter
        }
    }
}

// EOF
