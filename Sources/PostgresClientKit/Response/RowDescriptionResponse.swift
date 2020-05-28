//
//  RowDescriptionResponse.swift
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

internal class RowDescriptionResponse: Response {
    
    override internal init(responseBody: Connection.ResponseBody) throws {
        
        assert(responseBody.responseType == "T")
        
        let fieldCount = try responseBody.readUInt16()
        var columns = [ColumnMetadata]()
        
        for _ in 0..<fieldCount {
            
            let name = try responseBody.readUTF8String()
            let tableOID = try responseBody.readUInt32()
            let columnAttributeNumber = try responseBody.readUInt16()
            let dataTypeOID = try responseBody.readUInt32()
            let dataTypeSize = try responseBody.readUInt16()
            let dataTypeModifier = try responseBody.readUInt32()
            _ = try responseBody.readUInt16() // format code

            let column = ColumnMetadata(name: name,
                                        tableOID: tableOID,
                                        columnAttributeNumber: Int(columnAttributeNumber),
                                        dataTypeOID: dataTypeOID,
                                        dataTypeSize: Int(dataTypeSize),
                                        dataTypeModifier: dataTypeModifier)
            
            columns.append(column)
        }
        
        self.columns = columns
        
        try super.init(responseBody: responseBody)
    }
    
    internal let columns: [ColumnMetadata]
    

    //
    // MARK: CustomStringConvertible
    //
    
    override internal var description: String {
        return super.description + "(columns: \(columns))"
    }
}

// EOF
