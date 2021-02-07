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
    
    func test() throws {
        try time("ISO8601.parseTimestampWithTimeZone(_:)") {
            let (dc, d, ts) = ISO8601.parseTimestampWithTimeZone("2001-02-03 12:34:56.789-07:00")!
            return (dc, d, ts)
        }
        try time("ISO8601.parseTimestamp(_:)") {
            let (dc, d, ts) = ISO8601.parseTimestamp("2001-02-03 12:34:56.789")!
            return (dc, d, ts)
        }
        try time("ISO8601.parseDate(_:)") {
            let (dc, d, ts) = ISO8601.parseDate("2001-02-03")!
            return (dc, d, ts)
        }
        try time("ISO8601.parseTime(_:)") {
            let (dc, d, ts) = ISO8601.parseTime("12:34:56.789")!
            return (dc, d, ts)
        }
        try time("ISO8601.parseTimeWithTimeZone(_:)") {
            let (dc, d, ts) = ISO8601.parseTimeWithTimeZone("12:34:56.789-07:00")!
            return (dc, d, ts)
        }
    }
    
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
        // 12.267 us Postgres.isValidDate()                             (10000 iterations) true
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
            Postgres.isValidDate(dc2)
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
        //  1.040 us DateComponents.calendar set to UTC (timeZone not s(100000 iterations) ()
        //  1.019 us DateComponents.calendar set to other (timeZone not(100000 iterations) ()
        //  1.018 us DateComponents.calendar set to UTC (timeZone UTC) (100000 iterations) ()
        // 27.850 us DateComponents.calendar set to other (timeZone UTC(10000 iterations) ()
        // 10.542 us DateComponents.calendar set to UTC (timeZone other(10000 iterations) ()
        //  1.009 us DateComponents.calendar set to other (timeZone oth(100000 iterations) ()
        // 10.444 us DateComponents.calendar set to UTC (timeZone rando(10000 iterations) ()
        // 29.432 us DateComponents.calendar set to other (timeZone ran(10000 iterations) ()        //
        //
        // Conclusions:
        // - Setting the calendar of a DateComponents is expensive if the timeZone is set
        //   to something other than the time zone of the calendar

        let utcCalendar = Postgres.enUsPosixUtcCalendar
        
        var otherCalendar = utcCalendar
        otherCalendar.timeZone = TimeZone(secondsFromGMT: 3600)!
        
        var dc = DateComponents()
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 5
        dc.nanosecond = 365_000_000
        
        try time("DateComponents.calendar set to UTC (timeZone not set)") {
            dc.calendar = utcCalendar
        }
        
        try time("DateComponents.calendar set to other (timeZone not set)") {
            dc.calendar = otherCalendar
        }
        
        dc.timeZone = Postgres.utcTimeZone
        
        try time("DateComponents.calendar set to UTC (timeZone UTC)") {
            dc.calendar = utcCalendar
        }
        
        try time("DateComponents.calendar set to other (timeZone UTC)") {
            dc.calendar = otherCalendar
        }
        
        dc.timeZone = otherCalendar.timeZone
        
        try time("DateComponents.calendar set to UTC (timeZone other)") {
            dc.calendar = utcCalendar
        }
        
        try time("DateComponents.calendar set to other (timeZone other)") {
            dc.calendar = otherCalendar
        }
        
        dc.timeZone = TimeZone.current
        
        try time("DateComponents.calendar set to UTC (timeZone random)") {
            dc.calendar = utcCalendar
        }
        
        try time("DateComponents.calendar set to other (timeZone random)") {
            dc.calendar = otherCalendar
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

    var timeZonesByOffset = [Int: TimeZone]()

    func testInitializeTimeZone() throws {
        
        // Results (My Mac, release build):
        //
        // 2.791 us TimeZone initialize                               (100000 iterations) GMT+0100 (fixed)
        // 0.045 us TimeZone lookup by offset                         (10000000 iterations) GMT+0100 (fixed)
        //
        // Conclusions:
        // - Initializing a TimeZone is expensive, so caching helps
        
        let offset = 3600
        
        try time("TimeZone initialize") {
            let timeZone = TimeZone(secondsFromGMT: offset)!
            return timeZone
        }
        
        try time("TimeZone lookup by offset") {
            
            semaphore.wait()
            defer { semaphore.signal() }
            
            if let timeZone = timeZonesByOffset[offset] {
                return timeZone
            }
            
            let timeZone = TimeZone(secondsFromGMT: offset)!
            timeZonesByOffset[offset] = timeZone
            
            return timeZone
        }
    }
    
    func testIsValidDate() throws {

        // Results (My Mac, release build):
        //
        // 7.464 us DateComonents.isValidDate (with calendar & timeZon(100000 iterations) true
        // 9.179 us DateComonents.isValidDate(in:) (with calendar & ti(100000 iterations) true
        // 7.773 us DateComonents.isValidDate (with calendar but not t(100000 iterations) true
        // 9.078 us DateComonents.isValidDate(in:) (with neither calen(100000 iterations) true
        // 5.612 us By checking for lossless roundtrip                (100000 iterations) VALID
        //
        // Conclusions:
        // - Checking for a lossless roundtrip is somewhat faster, and exposes the Date as an
        //   interim result, which we can capture.

        let timeZone = TimeZone(secondsFromGMT: 0)!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone // https://bugs.swift.org/browse/SR-11569

        var dc = DateComponents()
        dc.calendar = calendar
        dc.timeZone = timeZone
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 59
        dc.nanosecond = 123_456_789

        try time("DateComonents.isValidDate (with calendar & timeZone)") {
            dc.isValidDate
        }

        try time("DateComonents.isValidDate(in:) (with calendar & timeZone)") {
            dc.isValidDate(in: calendar)
        }
        
        dc.timeZone = timeZone
        
        try time("DateComonents.isValidDate (with calendar but not time zone)") {
            dc.isValidDate
        }

        dc.calendar = nil

        try time("DateComonents.isValidDate(in:) (with neither calendar nor time zone)") {
            dc.isValidDate(in: calendar)
        }
        
        dc.timeZone = TimeZone(secondsFromGMT: 3600)
        
        try time("By checking for lossless roundtrip") {
            
            func getCalendar(for timeZone: TimeZone) -> Calendar {
                
                semaphore.wait()
                defer { semaphore.signal() }
                
                if let calendar = calendarsByTimeZone[timeZone] {
                    return calendar
                }
                
                var calendar = Calendar(identifier: .gregorian)
                calendar.locale = Postgres.enUsPosixLocale
                calendar.timeZone = timeZone
                calendarsByTimeZone[timeZone] = calendar
                
                return calendar
            }
            
            // Get a Calendar instance for the selected time zone.  Calendar.date(from:) is faster if
            // the timeZone property of the DateComponents instance equals the timeZone property of the
            // Calendar instance.  This also works around https://bugs.swift.org/browse/SR-10515.
            // *** check both of these assertions ***
            let calendar = getCalendar(for: dc.timeZone!)

            // Compute a Date from the DateComponents.
            guard let date = calendar.date(from: dc) else {
                return "FAILED1"
            }

            // Convert that Date back to a second DateComponents instance.
            let dc2 = calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)

            // For each DateComponents property of interest, check that the Date roundtrip preserved
            // its value.
            if (dc.year        != nil && dc2.year   != dc.year) ||
                (dc.month      != nil && dc2.month  != dc.month) ||
                (dc.day        != nil && dc2.day    != dc.day) ||
                (dc.hour       != nil && dc2.hour   != dc.hour) ||
                (dc.minute     != nil && dc2.minute != dc.minute) ||
                (dc.second     != nil && dc2.second != dc.second) {
                return "FAILED2"
            }

            // Date is backed by a Double (minimum 15 digits precision).  This isn't quite sufficient
            // to roundtrip with microsecond precision (yet alone nanosecond).  So we just check the
            // roundtripped value to millisecond resolution.
            if dc.nanosecond != nil && abs(dc2.nanosecond! - dc.nanosecond!) >= 001_000_000 {
                return "FAILED3"
            }
            
            return "VALID"
        }
    }
    
    func testDateFormatter() throws {
        
        let tstzFormatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSxxxxx"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()
        
        let tsFormatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()

        let dFormatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()
        
        let tFormatter: DateFormatter = {
            let df = DateFormatter()
            df.calendar = Postgres.enUsPosixUtcCalendar
            df.dateFormat = "HH:mm:ss.SSS"
            df.locale = Postgres.enUsPosixLocale
            df.timeZone = Postgres.utcTimeZone
            return df
        }()
        
        
        //
        // String->Date
        //
        
        try time("tstzFormatter String->Date") {
            tstzFormatter.date(from: "2001-02-03 12:34:56.789Z")
        }
        
        try time("tsFormatter String->Date") {
            tsFormatter.date(from: "2001-02-03 12:34:56.789")
        }
        
        try time("dFormatter String->Date") {
            dFormatter.date(from: "2001-02-03")
        }
        
        try time("tFormatter String->Date") {
            tFormatter.date(from: "12:34:56.789")
        }
        
        
        //
        // Date->String
        //
        
        let d = tstzFormatter.date(from: "2001-02-03 12:34:56.789Z")!
        
        try time("tstzFormatter Date->String") {
            tstzFormatter.string(from: d)
        }
        
        try time("tsFormatter Date->String") {
            tsFormatter.string(from: d)
        }
        
        try time("dFormatter Date->String") {
            dFormatter.string(from: d)
        }
        
        try time("tFormatter Date->String") {
            tFormatter.string(from: d)
        }
        
        
        //
        // Date->DateComponents
        //
        
        var calendar = Postgres.enUsPosixUtcCalendar
        calendar.timeZone = TimeZone(secondsFromGMT: 3600)!
        
        try time("tstz Date->DateComponents (no calendar -- API change!)") {
            calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone], from: d)
        }
        
        try time("tstz Date->DateComponents (calendar)") {
            calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone, .calendar], from: d)
        }
        
        try time("tstz Date->DateComponents (faster calendar)") {
            var dc = calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone], from: d)
            
            dc.calendar = calendar // obscenely slow!
            
            return dc
        }
        
        var dc2 = DateComponents() // something in here must be getting resolved...

        try time("tstz Date->DateComponents (fastest calendar)") {
            let dc = calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone], from: d)
            
            dc2.calendar = calendar
            dc2.year = dc.year
            dc2.month = dc.month
            dc2.day = dc.day
            dc2.hour = dc.hour
            dc2.minute = dc.minute
            dc2.second = dc.second
            dc2.nanosecond = dc.nanosecond
            dc2.timeZone = dc.timeZone
            
            return dc2
        }

        try time("ts Date->DateComponents") {
            calendar.dateComponents(
                [ .year, .month, .day, .hour, .minute, .second, .nanosecond], from: d)
        }
        
        try time("d Date->DateComponents") {
            calendar.dateComponents(
                [ .year, .month, .day], from: d)
        }
        
        try time("t Date->DateComponents") {
            calendar.dateComponents(
                [ .hour, .minute, .second, .nanosecond], from: d)
        }
        
        
        //
        // DateComponents->Date
        //
        
        var dc = DateComponents()
        dc.year = 2001
        dc.month = 2
        dc.day = 3
        dc.hour = 12
        dc.minute = 34
        dc.second = 56
        dc.nanosecond = 789
        dc.timeZone = TimeZone(secondsFromGMT: 3600)!
        
        calendar = Postgres.enUsPosixUtcCalendar
        
        try time("DateComponents->Date (different timeZone)") {
            calendar.date(from: dc)
        }
        
        calendar.timeZone = TimeZone(secondsFromGMT: 3600)!

        try time("DateComponents->Date (same timeZone)") {
            calendar.date(from: dc)
        }
        
        dc.timeZone = nil
        
        try time("DateComponents->Date (no timeZone)") {
            calendar.date(from: dc)
        }
        

        //
        // DateComponents.isValidDate(in:)
        //
        
        dc = DateComponents()
        dc.year = 2001
        dc.month = 2
        dc.day = 3
        dc.hour = 12
        dc.minute = 34
        dc.second = 56
        dc.nanosecond = 789
        dc.timeZone = TimeZone(secondsFromGMT: 3600)!
        
        calendar = Postgres.enUsPosixUtcCalendar

        try time("DateComponents.isValidDate(in:) (UTC vs +1)") {
            dc.isValidDate(in: calendar)
        }

        calendar.timeZone = TimeZone(secondsFromGMT: 3600)!

        try time("DateComponents.isValidDate(in:) (+1 vs +1)") {
            dc.isValidDate(in: calendar)
        }
        
        dc.timeZone = nil
        
        try time("DateComponents.isValidDate(in:) (+1 vs nil)") {
            dc.isValidDate(in: calendar)
        }
        
        calendar.timeZone = Postgres.utcTimeZone
        
        try time("DateComponents.isValidDate(in:) (UTC vs nil)") {
            dc.isValidDate(in: calendar)
        }
        
        dc.timeZone = Postgres.utcTimeZone
        
        try time("DateComponents.isValidDate(in:) (UTC vs UTC)") {
            dc.isValidDate(in: calendar)
        }
        
        try time("Postgres.isValidDate(_:) (timeZone set)") {
            Postgres.isValidDate(dc)
        }
        
        dc.timeZone = nil
        
        try time("Postgres.isValidDate(_:) (timeZone not set)") {
            Postgres.isValidDate(dc)
        }
    }
}

// EOF
