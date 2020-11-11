//
//  StartupRequest.swift
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

import Foundation

internal class StartupRequest: Request {
    
    internal init(user: String, database: String, applicationName: String) {
        self.user = user
        self.database = database
        self.applicationName = applicationName
    }
    
    private let user: String
    private let database: String
    private let applicationName: String
    
    
    //
    // MARK: Request
    //
    
    override var requestType: Character? {
        return nil
    }
    
    override var body: Data {
        
        var body = UInt32(196608).data // protocol version number (0x030000)
        
        body.append("user".dataZero)
        body.append(user.dataZero)
        
        body.append("database".dataZero)
        body.append(database.dataZero)
        
        body.append("application_name".dataZero)
        body.append(applicationName.dataZero)
        
        for parameter in Parameter.values {
            if let value = parameter.valueSetWhenConnecting {
                body.append(parameter.name.dataZero)
                body.append(value.dataZero)
            }
        }
        
        body.append(0) // no more parameters
        
        return body
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    override var description: String {
        return super.description + "(user: \(user), database: \(database), applicationName: \(applicationName))"
    }
}

// EOF
