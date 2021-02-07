//
//  FoundationBugs.swift
//  PostgresClientKitTests
//
//  Created by David Pitfield on 1/25/21.
//

import Foundation
import XCTest

class FoundationBugs: XCTestCase {

    func testSR10515() throws {
        
        // https://bugs.swift.org/browse/SR-10515
        //
        // Conclusion: fixed (verified in Swift 5.3.32 Linux)
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let calendarCopy = calendar // Calendar is a struct, so this should create a new instance

        let dc = calendarCopy.dateComponents(in: TimeZone(secondsFromGMT: 3600)!, from: Date())
        print("After dateComponents(in:from:) \(calendar.timeZone) \(calendarCopy.timeZone)")

        _ = calendarCopy.date(from: dc)
        print("After date(from:) \(calendar.timeZone) \(calendarCopy.timeZone)")
    }
    
    func testSR10516() throws {
        
        // https://bugs.swift.org/browse/SR-10516
        //
        // Conclusion: fixed (verified in Swift 5.3.32 Linux)

        let timeZone = TimeZone(secondsFromGMT: 0)!
        print(String(describing: timeZone.nextDaylightSavingTimeTransition))
    }
    
    func testSR11569() throws {
        
        // https://bugs.swift.org/browse/SR-11569
        //
        // Results (Swift 5.3.2 on Linux)
        //
        // isValidDate seems OK
        //      requires dc.calendar to be set
        //      does not require dc.timeZone to be set
        //
        // isValidDate(in:) is broken
        //      on Mac
        //          requires calendar.timeZone to be set
        //          does not require dc.calendar to be set
        //          does not require dc.timeZone to be set
        //          if dc.timeZone is set, must be same as calendar.timeZone
        //      on Linux
        //          does not require calendar.timeZone to be set            (different than Mac)
        //          does not require dc.calendar to be set                  (different than Mac)
        //          does not require dc.timeZone to be set                  (different than Mac)
        //          dc.timeZone can be different than calendar.timeZone     (different than Mac)
        //
        // Conclusion: isValidDate is fixed
        //             isValidDate(in:) is fixed in Linux but now broken on Mac
        
        let calendarTimeZone = TimeZone(secondsFromGMT: 0)!
        let dateComponentsTimeZone = TimeZone(secondsFromGMT: 3600)!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calendarTimeZone

        var dc = DateComponents()
        dc.calendar = calendar
        dc.timeZone = dateComponentsTimeZone
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 5
        dc.nanosecond = 6

        // Should be true.
        print("SR11569: dc.isValidDate = \(dc.isValidDate)")

        // Should be true.
        print("SR11569: dc.isValidDate(in: calendar) = \(dc.isValidDate(in: calendar))")
    }
}

// EOF
