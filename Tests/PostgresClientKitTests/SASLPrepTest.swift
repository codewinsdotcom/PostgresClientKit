//
//  SASLPrepTest.swift
//  PostgresClientKit
//
//  Copyright 2020 David Pitfield and the PostgresClientKit contributors
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

@testable import PostgresClientKit
import XCTest

/// Tests the SASLPrep transformation.
class SASLPrepTest: PostgresClientKitTestCase {
    
    func test() {
        
        func saslPrep(_ input: String, _ expectedOutput: String) {
            do {
                let output = try input.saslPrep(stringType: .storedString)
                XCTAssertEqual(output, expectedOutput)
            } catch {
                XCTFail(String(describing: error))
            }
        }
        
        func saslPrepError(_ input: String, expectedError: String.SASLPrepError) {
            XCTAssertThrowsError(try input.saslPrep(stringType: .storedString)) { error in
                switch (error, expectedError) {
                    
                case (String.SASLPrepError.prohibitedOutput(let scalar),
                      String.SASLPrepError.prohibitedOutput(let expectedScalar))
                      where scalar == expectedScalar:
                    break
                    
                case (String.SASLPrepError.prohibitedBidirectionalString(let string),
                      String.SASLPrepError.prohibitedBidirectionalString(let expectedString))
                      where string == expectedString:
                    break
                    
                case (String.SASLPrepError.unassignedCodePoint(let scalar),
                      String.SASLPrepError.unassignedCodePoint(let expectedScalar))
                      where scalar == expectedScalar:
                    break
                    
                default:
                    XCTFail(String(describing: error))
                }
            }
        }
        
        // Empty string
        saslPrep("", "")
        
        // ASCII string
        saslPrep("Hello, world!", "Hello, world!")
        
        // Mapping
        saslPrep("foo\u{00A0}bar", "foo bar")
        saslPrep("foo\u{00AD}bar", "foobar")
        
        // Normalization
        saslPrep("caf\u{00E9}", "caf\u{00E9}")
        saslPrep("cafe\u{0301}", "caf\u{00E9}")
        
        // Prohibited output
        saslPrepError("bell \u{0007}",
                      expectedError: .prohibitedOutput(scalar: "\u{0007}"))
        
        // Bi-directional string
        saslPrep("\u{0627}", "\u{0627}")
        saslPrep("\u{0627} \u{0628}", "\u{0627} \u{0628}")
        saslPrep("\u{0627} 1 \u{0628}", "\u{0627} 1 \u{0628}")
        
        saslPrepError("1 \u{0627}",
                      expectedError: .prohibitedBidirectionalString(string: "1 \u{0627}"))
        
        saslPrepError("\u{0627} 1",
                      expectedError: .prohibitedBidirectionalString(string: "\u{0627} 1"))
        
        saslPrepError("\u{0627} x \u{0628}",
                      expectedError: .prohibitedBidirectionalString(string: "\u{0627} x \u{0628}"))
        
        saslPrepError("x \u{0627}",
                      expectedError:.prohibitedBidirectionalString(string: "x \u{0627}"))
        
        saslPrepError("\u{0627} x",
                      expectedError: .prohibitedBidirectionalString(string: "\u{0627} x"))
        
        // Unassigned code point
        saslPrepError("unassigned \u{0221}",
                      expectedError: .unassignedCodePoint(scalar: "\u{0221}"))
        
        // Examples from RFC 4013 Section 3
        saslPrep("I\u{00AD}X", "IX")                      // 1. SOFT HYPHEN mapped to nothing
        saslPrep("user", "user")                          // 2. no transformation
        saslPrep("USER", "USER")                          // 3. case preserved, will not match #2
        saslPrep("\u{00AA}", "a")                         // 4. output is NFKC, input in ISO 8859-1
        saslPrep("\u{2168}", "IX")                        // 5. output is NFKC, will match #1
        
        saslPrepError("\u{0007}", expectedError:          // 6. Error - prohibited character
            .prohibitedOutput(scalar: "\u{0007}"))
        
        saslPrepError("\u{0627}\u{0031}", expectedError:  // 7. Error - bidirectional check
            .prohibitedBidirectionalString(
                string: "\u{0627}\u{0031}"))
    }
}

// EOF
