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

/// A prepared SQL statement.
///
/// Use `Connection.prepareStatement(text:)` to create a `Statement`.
///
/// Call `Statement.execute(parameterValues:)` to execute the `Statement`, specifying the values
/// of any parameters.
///
/// A `Statement` can be repeatedly executed, and the values of its parameters can be different
/// each time.
///
/// When a `Statement` is no longer required, call `Statement.close()` to release its Postgres
/// server resources.
public class Statement: CustomStringConvertible {
    
    /// Creates a `Statement`.
    ///
    /// - Parameters:
    ///   - connection: the `Connection`
    ///   - text: the SQL text
    internal init(connection: Connection, text: String) {
        self.connection = connection
        self.text = text
    }
    
    /// The `Connection` to which this `Statement` belongs.
    public let connection: Connection
    
    /// The SQL text.
    public let text: String
    
    /// Uniquely identifies this `Statement`.  Used in logging.
    internal let id = "Statement-\(Postgres.nextId())"

    /// Executes this `Statement`.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Parameter parameterValues: the values of the statement's parameters.  Index 0 is the
    ///     value of `$1`, index 1 is the value of `$2`, and so on.  A `nil` element represents
    ///     SQL `NULL`.
    /// - Returns: a `Cursor` containing the result
    /// - Throws: `PostgresError` if the operation fails
    @discardableResult public func execute(parameterValues: [PostgresValueConvertible?] = [ ])
        throws -> Cursor {
        
        return try connection.executeStatement(self, parameterValues: parameterValues)
    }
    
    /// Whether this `Statement` is closed.
    ///
    /// To close a `Statement`, call `close()`.
    public private(set) var isClosed = false

    /// Closes this `Statement`.
    ///
    /// Has no effect if this `Statement` is already closed.
    public func close() {
        connection.closeStatement(self)
        isClosed = true
    }
    
    /// Invokes `close()`.
    deinit {
        close()
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this `Statement`.
    public var description: String { return id }
}

// EOF
