//
//  BackendKeyDataResponse.swift
//  PostgresClientKit
//
//  Copyright 2019 David Pitfield and the PostgresClientKit contributors
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

internal class BackendKeyDataResponse: Response {
    
    override internal init(responseBody: Connection.ResponseBody) throws {
        
        assert(responseBody.responseType == "K")
        
        processID = try responseBody.readUInt32()
        secretKey = try responseBody.readUInt32()
        
        try super.init(responseBody: responseBody)
    }
    
    internal let processID: UInt32
    internal let secretKey: UInt32

    
    //
    // MARK: CustomStringConvertible
    //
    
    override internal var description: String {
        return super.description + "(processID: \(processID), secretKey: <masked>)"
    }
}

// EOF
