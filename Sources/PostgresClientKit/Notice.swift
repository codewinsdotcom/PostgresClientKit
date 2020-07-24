//
//  Notice.swift
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

/// A notice received from the Postgres server.
public struct Notice: CustomStringConvertible {
    
    internal init(fields: [Character: String]) {
        self.fields = fields
    }
    
    private let fields: [Character: String]
    
    /// `ERROR`, `FATAL`, or `PANIC` (in an error), or `WARNING`, `NOTICE`, `DEBUG`, `INFO`, or
    /// `LOG` (in a notice), or a localized translation of one of these.
    public var localizedSeverity: String? { return fields["S"] }
    
    /// `ERROR`, `FATAL`, or `PANIC` (in an error), or `WARNING`, `NOTICE`, `DEBUG`, `INFO`, or
    /// `LOG` (in a notice).  Identical to `localizedSeverity` except that the contents are never
    /// localized.
    public var severity: String? { return fields["V"] }
    
    /// The SQLSTATE code for the error.  Not localizable.
    ///
    /// - SeeAlso: [Postgres:
    ///     Error Codes](https://www.postgresql.org/docs/12/static/errcodes-appendix.html)
    public var code: String? { return fields["C"] }
    
    ///  The primary human-readable error message.  Accurate but terse (typically one line).
    public var message: String? { return fields["M"] }
    
    /// A secondary error message carrying more detail about the problem.  Might run to multiple
    /// lines.
    public var detail: String? { return fields["D"] }
    
    /// A suggestion of what to do about the problem.  This is intended to differ from `detail` in
    /// that it offers advice (potentially inappropriate) rather than hard facts.  Might run to
    /// multiple lines.
    public var hint: String? { return fields["H"] }
    
    /// An index into the original query string.  The first character has index 1, and positions are
    /// measured in characters not bytes.
    public var position: String? { return fields["P"] }
    
    /// An index into an internally generated command (`internalQuery`) rather than the one
    /// submitted by the client.  The first character has index 1, and positions are measured in
    /// characters not bytes.
    public var internalPosition: String? { return fields["p"] }
    
    /// The text of a failed internally-generated command.  This could be, for example, a SQL query
    /// issued by a PL/pgSQL function.
    public var internalQuery: String? { return fields["q"] }
    
    /// The context in which the error occurred.  Presently this includes a call stack traceback of
    /// active procedural language functions and internally-generated queries.  The trace is one
    /// entry per line, most recent first.
    public var context: String? { return fields["W"] }
    
    /// If the error was associated with a specific database object, the name of the schema
    /// containing that object, if any.
    public var schema: String? { return fields["s"] }
    
    /// If the error was associated with a specific table, the name of the table.  (Refer to
    /// `schema` for the name of the table's schema.)
    public var table: String? { return fields["t"] }
    
    /// If the error was associated with a specific table column, the name of the column.  (Refer to
    /// `schema` and `table` to identify the table.)
    public var column: String? { return fields["c"] }
    
    /// If the error was associated with a specific data type, the name of the data type.  (Refer to
    /// `schema` for the name of the data type's schema.)
    public var dataType: String? { return fields["d"] }
    
    /// If the error was associated with a specific constraint, the name of the constraint.  Refer
    /// to the above properties for the associated table or domain.  (For this purpose, indexes are
    /// treated as constraints, even if they weren't created with constraint syntax.)
    public var constraint: String? { return fields["n"] }
    
    /// The file name of the source-code location where the error was reported.
    public var file: String? { return fields["F"] }
    
    /// The line number of the source-code location where the error was reported.
    public var line: String? { return fields["L"] }
    
    /// The name of the source-code routine reporting the error.
    public var routine: String? { return fields["R"] }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `Notice`.
    public var description: String {
        
        var s = "Notice("
        
        if localizedSeverity != nil { s += "\n  localizedSeverity: \(localizedSeverity!)" }
        if severity != nil { s += "\n  severity: \(severity!)" }
        if code != nil { s += "\n  code: \(code!)" }
        if message != nil { s += "\n  message: \(message!)" }
        if detail != nil { s += "\n  detail: \(detail!)" }
        if hint != nil { s += "\n  hint: \(hint!)" }
        if position != nil { s += "\n  position: \(position!)" }
        if internalPosition != nil { s += "\n  internalPosition: \(internalPosition!)" }
        if internalQuery != nil { s += "\n  internalQuery: \(internalQuery!)" }
        if context != nil { s += "\n  context: \(context!)" }
        if schema != nil { s += "\n  schema: \(schema!)" }
        if table != nil { s += "\n  table: \(table!)" }
        if column != nil { s += "\n  column: \(column!)" }
        if dataType != nil { s += "\n  dataType: \(dataType!)" }
        if constraint != nil { s += "\n  constraint: \(constraint!)" }
        if file != nil { s += "\n  file: \(file!)" }
        if line != nil { s += "\n  line: \(line!)" }
        if routine != nil { s += "\n  routine: \(routine!)" }
        
        s += "\n)"
        
        return s
    }
}

// EOF
