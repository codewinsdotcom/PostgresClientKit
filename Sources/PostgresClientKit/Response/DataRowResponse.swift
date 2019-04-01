//
//  DataRowResponse.swift
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

internal class DataRowResponse: Response {
    
    override internal init(responseBody: Connection.ResponseBody) throws {
        
        assert(responseBody.responseType == "D")
        
        let columnCount = try responseBody.readUInt16()
        var columns = [PostgresValue]()
        
        for _ in 0..<columnCount {
            let byteCount = try responseBody.readUInt32()
            
            let rawValue = (byteCount == UInt32.max) ?
                nil :
                try responseBody.readUTF8String(byteCount: Int(byteCount))
            
            columns.append(PostgresValue(rawValue))
        }
        
        self.columns = columns
        
        try super.init(responseBody: responseBody)
    }
    
    internal let columns: [PostgresValue]
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    override internal var description: String {
        return super.description + "(columns: \(columns))"
    }
}

// EOF
