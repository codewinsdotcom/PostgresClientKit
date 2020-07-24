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

/// The result of successfully executing a `Statement`.
///
/// - Note: Do not confuse this `Cursor` class with the SQL cursors created by the [SQL DECLARE
///     command](https://www.postgresql.org/docs/12/sql-declare.html).  The `Cursor` class exposes
///     the result of executing a *single* SQL command.  A SQL cursor, on other other hand, exposes
///     a query's result by *repeated* execution of the SQL `FETCH` command.
///
/// When a `Cursor` is no longer required, call `Cursor.close()` to release its Postgres server
/// resources.  A `Cursor` is implicitly closed as a side effect of certain operations on a
/// connection; refer to the `Connection` documentation for a full list.  A `Cursor` is also
/// automatically closed by its deinitializer.
///
/// A `Cursor` in PostgresClientKit corresponds to the unnamed portal of the connection on the
/// Postgres server.
///
/// - SeeAlso: [Postgres: Message Flow - Extended
///     Query](https://www.postgresql.org/docs/12/protocol-flow.html#PROTOCOL-FLOW-EXT-QUERY)
public class Cursor: Sequence, IteratorProtocol {
    
    /// Creates a `Cursor`.
    ///
    /// - Parameters:
    ///   - statement: the statement
    ///   - columns: metadata about the columns in the results, or `nil` if column metadata is not
    ///       available
    internal init(statement: Statement, columns: [ColumnMetadata]?) {
        self.statement = statement
        self.columns = columns
    }
    
    /// Uniquely identifies this `Cursor`.
    ///
    /// Used in logging and to formulate the `description`.
    public let id = "Cursor-\(Postgres.nextId())"
    
    /// Metadata about the columns in the results, or `nil` if column metadata is not available.
    ///
    /// For column metadata to be available, set `retrieveColumnMetadata` to `true` in calling
    /// `Statement.execute(parameterValues:retrieveColumnMetadata:)`.
    ///
    /// Each element in the returned value describes the corresponding element in the `columns`
    /// of each `Row` of the results.
    public let columns: [ColumnMetadata]?
    
    /// The `Statement` to which this `Cursor` belongs.
    public let statement: Statement
    
    /// The number of rows affected by the `Statement`.
    ///
    /// The specific interpretation of this value depends on the SQL command performed:
    ///
    /// - `INSERT`: the number of rows inserted
    /// - `UPDATE`: the number of rows updated
    /// - `DELETE`: the number of rows deleted
    /// - `SELECT` or `CREATE TABLE AS`: the number of rows retrieved
    /// - `MOVE`: the number of rows by which the SQL cursor's position changed
    /// - `FETCH`: the number of rows retrieved from the SQL cursor
    /// - `COPY`: the number of rows copied
    ///
    /// If this `Cursor` has one or more rows, this property is `nil` until the final row has been
    /// retrieved (in other words, until `next()` returns `nil`).
    public internal(set) var rowCount: Int? = nil
    
    /// Whether this `Cursor` is closed.
    ///
    /// To close a `Cursor`, call `close()`.
    public var isClosed: Bool {
        return statement.connection.isCursorClosed(self)
    }
    
    /// Closes this `Cursor`.
    ///
    /// Has no effect if this `Cursor` is already closed.
    public func close() {
        statement.connection.closeCursor(self)
        assert(isClosed)
    }
    
    /// Invokes `close()`.
    deinit {
        close()
    }
    
    
    //
    // MARK: IteratorProtocol
    //
    
    /// Gets the next `Row` of this `Cursor`.
    ///
    /// Example of use:
    ///
    ///     let cursor: Cursor = ...
    ///     for row in cursor {
    ///         let columns = try row.get().columns // throws upon an error
    ///         ...
    ///     }
    ///
    /// - Returns: a value that represents success (with an associated `Row`) or failure (with
    ///     an associated `Error`); or `nil` if there are no more rows
    public func next() -> Result<Row, Error>? {
        do {
            if let row = try statement.connection.nextRowOfCursor(self) {
                return .success(row)
            } else {
                return nil
            }
        } catch {
            return .failure(error)
        }
    }
    

    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this `Cursor`.
    public var description: String { return id }
}

// EOF
