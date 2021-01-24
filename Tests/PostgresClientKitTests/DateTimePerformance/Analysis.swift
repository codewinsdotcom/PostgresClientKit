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
}

// EOF
