//
//  Statement.swift
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

public class Statement: CustomStringConvertible {
    
    internal init(connection: Connection, text: String) {
        self.connection = connection
        self.text = text
    }
    
    public let connection: Connection
    public let text: String
    internal let id = "Statement-\(Postgres.nextId())"

    @discardableResult public func execute(parameterValues: [ValueConvertible?] = [ ])
        throws -> Cursor {
        
        return try connection.executeStatement(self, parameterValues: parameterValues)
    }
    
    public private(set) var isClosed = false

    public func close() {
        connection.closeStatement(self)
        isClosed = true
    }
    
    deinit {
        close()
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this statement.
    public var description: String { return id }
}

// EOF
