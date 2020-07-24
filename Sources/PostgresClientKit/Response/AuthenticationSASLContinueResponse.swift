//
//  AuthenticationSASLContinueResponse.swift
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

internal class AuthenticationSASLContinueResponse: AuthenticationResponse {
    
    override internal init(responseBody: Connection.ResponseBody) throws {
        
        assert(responseBody.responseType == "R")
        
        serverFirstMessage = try responseBody.readUTF8String(byteCount: responseBody.bytesRemaining)
        
        try super.init(responseBody: responseBody)
    }
    
    internal let serverFirstMessage: String
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    override internal var description: String {
        return super.description + "(serverFirstMessage: \(serverFirstMessage))"
    }
}

// EOF
