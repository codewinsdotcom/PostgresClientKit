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
/// Call `Statement.execute(parameterValues:retrieveColumnMetadata:)` to execute the `Statement`,
/// specifying the values of any parameters.
///
/// A `Statement` can be repeatedly executed, and the values of its parameters can be different
/// each time.
///
/// When a `Statement` is no longer required, call `Statement.close()` to release its Postgres
/// server resources.  A `Statement` is automatically closed by its deinitializer.
///
/// A `Statement` in PostgresClientKit corresponds to a prepared statement on the Postgres server
/// whose name is the `id` of the `Statement`.
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
    
    /// Uniquely identifies this `Statement`.
    ///
    /// The `id` of a `Statement` in PostgresClientKit is also the name of the prepared statement on
    /// the Postgres server.  The `id` is also used in logging and to formulate the `description`.
    public let id = "Statement-\(Postgres.nextId())"
    
    /// The `Connection` to which this `Statement` belongs.
    public let connection: Connection
    
    /// The SQL text.
    public let text: String
    
    /// Executes this `Statement`.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Parameters:
    ///   - parameterValues: the values of the statement's parameters.  Index 0 is the value of
    ///     `$1`, index 1 is the value of `$2`, and so on.  A `nil` element represents SQL `NULL`.
    ///   - retrieveColumnMetadata: whether to retrieve metadata about the columns in the results
    /// - Returns: a `Cursor` containing the result
    /// - Throws: `PostgresError` if the operation fails
    @discardableResult public func execute(parameterValues: [PostgresValueConvertible?] = [ ],
                                           retrieveColumnMetadata: Bool = false)
        throws -> Cursor {
        
            return try connection.executeStatement(self,
                                                   parameterValues: parameterValues,
                                                   retrieveColumnMetadata: retrieveColumnMetadata)
    }
    
    /// Whether this `Statement` is closed.
    ///
    /// To close a `Statement`, call `close()`.
    public var isClosed: Bool {
        
        if connection.isClosed {
            _isClosed = true
        }
        
        return _isClosed
    }
    
    private var _isClosed = false

    /// Closes this `Statement`.
    ///
    /// Any previous `Cursor` for the `connection` is closed.
    ///
    /// Has no effect if this `Statement` is already closed.
    public func close() {
        connection.closeStatement(self)
        _isClosed = true
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
