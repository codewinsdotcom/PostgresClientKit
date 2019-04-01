//
//  Cursor.swift
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

public class Cursor: CustomStringConvertible {
    
    internal init(statement: Statement) {
        self.statement = statement
    }
    
    public let statement: Statement
    
    internal let id = "Cursor-\(Postgres.nextId())"
    
    public var rows: Rows {
        return Rows(cursor: self)
    }
    
    public internal(set) var rowCount: Int? = nil
    
    public var isClosed: Bool {
        return statement.connection.isCursorClosed(self)
    }
    
    public func close() {
        statement.connection.closeCursor(self)
        assert(isClosed)
    }
    
    deinit {
        close()
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this cursor.
    public var description: String { return id }
}

// EOF
