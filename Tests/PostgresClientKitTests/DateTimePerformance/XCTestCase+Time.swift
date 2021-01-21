//
//  XCTestCase+Time.swift
//  PostgresClientKitTests
//
//  Created by David Pitfield on 1/20/21.
//

import XCTest
extension XCTestCase {
    
    static let utcTimeZone = TimeZone(secondsFromGMT: 0)!

    func time(_ name: String, operation: () throws -> Any) throws {
        
        let output = try String(describing: operation())
        var iterations = 100
        var elapsedSeconds = 0.0
        
        while elapsedSeconds < 0.1 {
            
            iterations *= 10
            let start = Date()
            
            for _ in 0..<iterations {
                _ = try operation()
            }
            
            elapsedSeconds = Date().timeIntervalSince(start)
        }

        let averageMicroseconds = elapsedSeconds / Double(iterations) * 1_000_000
        
        print(String(format: " %9.3f us %@ (%d iterations) %@",
                     averageMicroseconds,
                     name.padding(toLength: 50, withPad: " ", startingAt: 0),
                     iterations,
                     output))
    }
}

// EOF
