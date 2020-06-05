//
//  ColumnMetadata.swift
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

/// Metadata about a column in the results of executing a `Statement`.
public struct ColumnMetadata {
    
    /// The name of the column.
    public let name: String
    
    /// If the column can be identified as a column of a specific table, the object ID of that
    /// table; otherwise zero.
    ///
    /// - SeeAlso: [pg_attribute.attrelid](https://www.postgresql.org/docs/12/catalog-pg-attribute.html)
    public let tableOID: UInt32
    
    /// If the column can be identified as a column of a specific table, the attribute number of
    /// the column in that table; otherwise zero.
    ///
    /// - SeeAlso: [pg_attribute.attnum](https://www.postgresql.org/docs/12/catalog-pg-attribute.html)
    public let columnAttributeNumber: Int
    
    /// The object ID of the column's data type.
    ///
    /// - SeeAlso: [pg_type.oid](https://www.postgresql.org/docs/12/catalog-pg-type.html)
    public let dataTypeOID: UInt32
    
    /// The data type size.
    ///
    /// - SeeAlso: [pg_type.typlen](https://www.postgresql.org/docs/12/catalog-pg-type.html)
    public let dataTypeSize: Int
    
    /// The data type modifier.
    ///
    /// - SeeAlso: [pg_attribute.atttypmod](https://www.postgresql.org/docs/12/catalog-pg-attribute.html)
    public let dataTypeModifier: UInt32
}

// EOF
