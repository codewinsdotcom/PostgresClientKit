//
//  Row.swift
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

/// A `Row` exposed by a `Cursor`.
public struct Row: CustomStringConvertible {
    
    /// Creates a `Row`.
    ///
    /// - Parameters:
    ///   - columns: the column values
    ///   - columnNameRowDecoder: the `RowDecoder` instance used to decode by column name
    internal init(columns: [PostgresValue], columnNameRowDecoder: RowDecoder?) {
        self.columns = columns
        self.columnNameRowDecoder = columnNameRowDecoder
    }
    
    /// The values of the columns for this `Row`.
    public var columns: [PostgresValue]
    
    /// The `RowDecoder` instance used to decode by column name.
    private let columnNameRowDecoder: RowDecoder?

    /// Decodes this `Row` to create an instance of the specified type.
    ///
    /// The type specified must conform to the `Decodable` protocol.  This method uses the column
    /// metadata provided by `Cursor.columns` to create a new instance of that type whose stored
    /// properties are set to the values of like-named `columns`.  (To make this column metadata
    /// available, set `retrieveColumnMetadata` to `true` in calling
    /// `Statement.execute(parameterValues:retrieveColumnMetadata:)`.)
    ///
    /// The supported property types are a superset of the types supported by `PostgresValue`:
    ///
    /// | Type of stored property         | Conversion performed                    |
    /// | ------------------------------- | --------------------------------------- |
    /// | `Bool`                          | `postgresValue.bool()`                  |
    /// | `String`                        | `postgresValue.string()`                |
    /// | `Double`                        | `postgresValue.double()`                |
    /// | `Float`                         | `Float(postgresValue.double())`         |
    /// | `Int`                           | `postgresValue.int()`                   |
    /// | `Int8`                          | `Int8(postgresValue.string())`          |
    /// | `Int16`                         | `Int16(postgresValue.string())`         |
    /// | `Int32`                         | `Int32(postgresValue.string())`         |
    /// | `Int64`                         | `Int64(postgresValue.string())`         |
    /// | `UInt`                          | `UInt(postgresValue.string())`          |
    /// | `UInt8`                         | `UInt8(postgresValue.string())`         |
    /// | `UInt16`                        | `UInt16(postgresValue.string())`        |
    /// | `UInt32`                        | `UInt32(postgresValue.string())`        |
    /// | `UInt64`                        | `UInt64(postgresValue.string())`        |
    /// | `PostgresByteA`                 | `postgresValue.byteA()`                 |
    /// | `PostgresTimestampWithTimeZone` | `postgresValue.timestampWithTimeZone()` |
    /// | `PostgresTimestamp`             | `postgresValue.timestamp()`             |
    /// | `PostgresDate`                  | `postgresValue.date()`                  |
    /// | `PostgresTime`                  | `postgresValue.time()`                  |
    /// | `PostgresTimeWithTimeZone`      | `postgresValue.timeWithTimeZone()`      |
    /// | `Date`                          | see below                               |
    ///
    /// Foundation `Date` stored properties are decoded as follows:
    /// - `postgresValue.timestampWithTimeZone().date`, if successful;
    /// - otherwise `postgresValue.timestamp().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.date().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.time().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.timeWithTimeZone().date`, if successful
    ///
    /// (Instead of `Date`, consider using `PostgresTimestampWithTimeZone`, `PostgresTimestamp`,
    /// `PostgresDate`, `PostgresTime`, and `PostgresTimeWithTimeZone` whenever possible.)
    ///
    /// Example:
    ///
    ///     struct Weather: Decodable {
    ///         let date: PostgresDate
    ///         let city: String
    ///         let temp_lo: Int
    ///         let temp_hi: Int
    ///         let prcp: Double?
    ///     }
    ///
    ///     let connection: Connection = ...
    ///
    ///     // Note that the columns must have the same names as the Weather
    ///     // properties, but may be in a different order.
    ///     let text = "SELECT city, temp_lo, temp_hi, prcp, date FROM weather;"
    ///     let statement = try connection.prepareStatement(text: text)
    ///     let cursor = try statement.execute(retrieveColumnMetadata: true)
    ///
    ///     for row in cursor {
    ///         let weather = try row.get().decodeByColumnName(Weather.self)
    ///         ...
    ///     }
    ///
    /// - Parameters:
    ///   - type: the type of instance to create
    ///   - defaultTimeZone: the default time zone for certain conversions to Foundation `Date`
    ///       (see above); if `nil` then the UTC time zone is used
    /// - Returns: an instance of the specified type
    /// - Throws: `PostgresError.columnMetadataNotAvailable` if column metadata is not available;
    ///           `DecodingError` if the operation otherwise fails
    public func decodeByColumnName<T: Decodable>(_ type: T.Type,
                                                 defaultTimeZone: TimeZone? = nil) throws -> T {
        
        guard let columnNameRowDecoder = columnNameRowDecoder else {
            throw PostgresError.columnMetadataNotAvailable
        }
        
        return try columnNameRowDecoder.decode(
            type, from: columns, defaultTimeZone: defaultTimeZone ?? ISO8601.utcTimeZone)
    }

    /// Decodes this `Row` to create an instance of the specified type.
    ///
    /// The type specified must conform to the `Decodable` protocol.  This method matches `columns`
    /// to stored properties based on decoding order: the first property decoded is assigned the
    /// value of `columns[0]`, the second property is assigned the value of `columns[1]`, and so
    /// on.  By default, a `Decodable` type decodes its properties in declaration order.  This
    /// default behavior can be overridden by providing implementations of the `CodingKeys` enum
    /// and the `init(from:)` initializer.  Refer to [Apple's developer documentation](
    /// https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
    /// for further information.
    ///
    /// The supported property types are a superset of the types supported by `PostgresValue`:
    ///
    /// | Type of stored property         | Conversion performed                    |
    /// | ------------------------------- | --------------------------------------- |
    /// | `Bool`                          | `postgresValue.bool()`                  |
    /// | `String`                        | `postgresValue.string()`                |
    /// | `Double`                        | `postgresValue.double()`                |
    /// | `Float`                         | `Float(postgresValue.double())`         |
    /// | `Int`                           | `postgresValue.int()`                   |
    /// | `Int8`                          | `Int8(postgresValue.string())`          |
    /// | `Int16`                         | `Int16(postgresValue.string())`         |
    /// | `Int32`                         | `Int32(postgresValue.string())`         |
    /// | `Int64`                         | `Int64(postgresValue.string())`         |
    /// | `UInt`                          | `UInt(postgresValue.string())`          |
    /// | `UInt8`                         | `UInt8(postgresValue.string())`         |
    /// | `UInt16`                        | `UInt16(postgresValue.string())`        |
    /// | `UInt32`                        | `UInt32(postgresValue.string())`        |
    /// | `UInt64`                        | `UInt64(postgresValue.string())`        |
    /// | `PostgresByteA`                 | `postgresValue.byteA()`                 |
    /// | `PostgresTimestampWithTimeZone` | `postgresValue.timestampWithTimeZone()` |
    /// | `PostgresTimestamp`             | `postgresValue.timestamp()`             |
    /// | `PostgresDate`                  | `postgresValue.date()`                  |
    /// | `PostgresTime`                  | `postgresValue.time()`                  |
    /// | `PostgresTimeWithTimeZone`      | `postgresValue.timeWithTimeZone()`      |
    /// | `Date`                          | see below                               |
    ///
    /// Foundation `Date` stored properties are decoded as follows:
    /// - `postgresValue.timestampWithTimeZone().date`, if successful;
    /// - otherwise `postgresValue.timestamp().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.date().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.time().date(in: defaultTimeZone)`, if successful;
    /// - otherwise `postgresValue.timeWithTimeZone().date`, if successful
    ///
    /// (Instead of `Date`, consider using `PostgresTimestampWithTimeZone`, `PostgresTimestamp`,
    /// `PostgresDate`, `PostgresTime`, and `PostgresTimeWithTimeZone` whenever possible.)
    ///
    /// Example:
    ///
    ///     struct Weather: Decodable {
    ///         let city: String
    ///         let lowestTemperature: Int
    ///         let highestTemperature: Int
    ///         let precipitation: Double?
    ///         let date: PostgresDate
    ///     }
    ///
    ///     let connection: Connection = ...
    ///
    ///     // Notice that the columns must be in the same order as the Weather
    ///     // properties, but may have different names.
    ///     let text = "SELECT city, temp_lo, temp_hi, prcp, date FROM weather;"
    ///     let statement = try connection.prepareStatement(text: text)
    ///     let cursor = try statement.execute()
    ///
    ///     for row in cursor {
    ///         let weather = try row.get().decodeByColumnIndex(Weather.self)
    ///         ...
    ///     }
    ///
    /// - Parameters:
    ///   - type: the type of instance to create
    ///   - defaultTimeZone: the default time zone for certain conversions to Foundation `Date`
    ///       (see above); if `nil` then the UTC time zone is used
    /// - Returns: an instance of the specified type
    /// - Throws: `DecodingError` if the operation fails
    public func decodeByColumnIndex<T: Decodable>(_ type: T.Type,
                                                  defaultTimeZone: TimeZone? = nil) throws -> T {

        // We cannot assume the decoding order is stable across successive rows of the cursor,
        // so create a new RowDecoder instance for each row.
        return try RowDecoder(columns: nil).decode(
            type, from: columns, defaultTimeZone: defaultTimeZone ?? ISO8601.utcTimeZone)
    }


    //
    // MARK: CustomStringConvertible
    //
    
    /// A string representation of this `Row`.
    public var description: String {
        return "Row(columns: \(columns))"
    }
}

// EOF
