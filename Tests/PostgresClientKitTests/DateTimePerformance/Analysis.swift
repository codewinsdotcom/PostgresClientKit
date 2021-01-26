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
    
    
    func testDateComponentsCalendar() throws {
        
        // Results (My Mac, release build):
        //
        //  1.048 us DateComponents.calendar set (timeZone not set)    (100000 iterations) ()
        // 10.485 us DateComponents.calendar set (timeZone set)        (10000 iterations) ()
        //
        // Conclusions:
        // - Setting the calendar of a DateComponents is expensive if the timeZone is set

        let calendar = Postgres.enUsPosixUtcCalendar
        
        var dc = DateComponents()
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 5
        dc.nanosecond = 365_000_000
        
        try time("DateComponents.calendar set (timeZone not set)") {
            dc.calendar = calendar
        }
        
        dc.timeZone = TimeZone.current
        
        try time("DateComponents.calendar set (timeZone set)") {
            dc.calendar = calendar
        }
    }
    
    func testDateComponentsTimeZone() throws {
    
        // Results (My Mac, release build):
        //
        // 0.054 us DateComponents.timeZone set (calendar not set)    (10000000 iterations) ()
        // 0.051 us DateComponents.timeZone set (calendar set)        (10000000 iterations) ()
        //
        // Conclusions:
        // - Setting the timeZone of a DateComponents is cheap
        
        let tz = TimeZone.current
        
        var dc = DateComponents()
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 5
        dc.nanosecond = 365_000_000

        try time("DateComponents.timeZone set (calendar not set)") {
            dc.timeZone = tz
        }
        
        dc.calendar = Postgres.enUsPosixUtcCalendar

        try time("DateComponents.timeZone set (calendar set)") {
            dc.timeZone = tz
        }
    }
    
    func testCalendarTimeZone() throws {

        // Results (My Mac, release build):
        //
        // 0.081 us Calendar.timeZone set                             (10000000 iterations) ()
        //
        // Conclusions:
        // - Setting the timeZone of an existing Calendar is cheap (but see below)
        
        let tz = TimeZone.current
        var calendar = Postgres.enUsPosixUtcCalendar
        
        try time("Calendar.timeZone set") {
            calendar.timeZone = tz
        }
    }
    
    func testCalendarCopy() throws {

        // Results (My Mac, release build):
        //
        //  0.234 us Calendar copy                                     (1000000 iterations) America/Los_Angeles (current)
        // 11.294 us Calendar copy + set timeZone                      (10000 iterations) America/Los_Angeles (current)        //
        //
        // Conclusions:
        // - Creating a copy of a Calendar is cheap, but setting the timeZone on that copy is expensive
        
        var calendar = Postgres.enUsPosixUtcCalendar
        let tz = TimeZone.current
        calendar.timeZone = tz
        
        try time("Calendar copy") {
            let calendar2 = calendar
            return calendar2.timeZone
        }
        
        try time("Calendar copy + set timeZone") {
            var calendar2 = calendar
            calendar2.timeZone = tz
            return calendar2.timeZone
        }
    }
    
    var calendarsByTimeZone = [TimeZone: Calendar]()
    
    func testInitializeCalendar() throws {
        
        // Results (My Mac, release build):
        //
        // 20.362 us Calendar initialize                               (10000 iterations) gregorian (fixed)
        //  0.203 us Calendar lookup by TimeZone                       (1000000 iterations) gregorian (fixed)
        //
        // Conclusions:
        // - Initializing a calendar is expensive, so caching helps

        let locale = Postgres.enUsPosixLocale
        let timeZone = TimeZone.current
        
        try time("Calendar initialize") {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            calendar.timeZone = timeZone
            return calendar
        }
        
        try time("Calendar lookup by TimeZone") {
            
            semaphore.wait()
            defer { semaphore.signal() }
            
            if let calendar = calendarsByTimeZone[timeZone] {
                return calendar
            }
            
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = locale
            calendar.timeZone = timeZone
            calendarsByTimeZone[timeZone] = calendar
            
            return calendar
        }
    }
}

// EOF
