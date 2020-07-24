//
//  SCRAMSHA256AuthenticatorTest.swift
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

/// Tests `SCRAMSHA256Authenticator`
class SCRAMSHA256AuthenticatorTest: PostgresClientKitTestCase {
    
    // Test case from RFC 7677 Section 3.
    func test() throws {
        
        let authenticator = SCRAMSHA256Authenticator(user: "user",
                                                     password: "pencil",
                                                     cnonce: "rOprNGfwEbeRWgbNEkqO")
        
        let clientFirstMessage = try authenticator.prepareClientFirstMessage()
        XCTAssertEqual(clientFirstMessage,
            "n,,n=user,r=rOprNGfwEbeRWgbNEkqO")
        
        let serverFirstMessage =
            "r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0," +
            "s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096"
        try authenticator.processServerFirstMessage(serverFirstMessage)
        
        let clientFinalMessage = try authenticator.prepareClientFinalMessage()
        XCTAssertEqual(clientFinalMessage,
            "c=biws,r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0," +
            "p=dHzbZapWIk4jUhN+Ute9ytag9zjfMHgsqmmiz7AndVQ=")
        
        let serverFinalMessage = "v=6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4="
        try authenticator.processServerFinalMessage(serverFinalMessage)
    }
}

// EOF
