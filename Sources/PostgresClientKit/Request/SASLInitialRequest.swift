//
//  SASLInitialRequest.swift
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

import Foundation

internal class SASLInitialRequest: Request {
    
    internal init(mechanism: String, clientFirstMessage: String) {
        self.mechanism = mechanism
        self.clientFirstMessage = clientFirstMessage
    }
    
    private let mechanism: String
    private let clientFirstMessage: String
    
    
    //
    // MARK: Request
    //
    
    override var requestType: Character? {
        return "p"
    }
    
    override var body: Data {
        
        var body = mechanism.dataZero
        
        if clientFirstMessage.isEmpty {
            body.append(UInt32.max.data)
        } else {
            let clientFirstMessageData = clientFirstMessage.data
            body.append(UInt32(clientFirstMessageData.count).data)
            body.append(clientFirstMessageData)
        }
        
        return body
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    override var description: String {
        return super.description + "(mechanism: \(mechanism), clientFirstMessage: \(clientFirstMessage))"
    }
}

// EOF
