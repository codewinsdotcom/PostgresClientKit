//
//  RowDecoder.swift
//  PostgresClientKit
//
//  Copyright 2022 Soroush Khanlou, David Pitfield, and the PostgresClientKit
//  contributors
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

/// Decodes `Row` instances to instances of `Decodable` swift types.
///
/// Refer to the associated public APIs for further information:
/// - `Row.decodeByColumnName(_:defaultTimeZone:)`
/// - `Row.decodeByColumnIndex(_:defaultTimeZone:)`
internal class RowDecoder {
    
    /// Creates a `RowDecoder`.
    ///
    /// - Parameter columns: the column metadata used to decode by column name, or `nil` to decode
    ///     by column index
    init(columns: [ColumnMetadata]?) {
        inferColumnNames = (columns == nil) // whether to decode by column index

        for column in (columns ?? []) {
            columnIndicesByName[column.name] = columnIndicesByName.count
        }
    }
    
    /// Whether to infer the column names from the order in which the stored properties are decoded
    /// ("decode by column index").
    private let inferColumnNames: Bool
    
    /// A map of columns' names (either explicitly provided by column metadata or inferred from the
    /// decoding order) to the indices of those columns' values.
    private var columnIndicesByName = [String: Int]()
    
    /// Decodes a row to create an instance of the specified type.
    ///
    /// - Parameters:
    ///   - type: the type of instance to create
    ///   - postgresValues: the values of the columns for the row
    ///   - defaultTimeZone: the default time zone for certain conversions to Foundation `Date`
    /// - Returns: an instance of the specified type
    /// - Throws: `DecodingError` if the operation fails
    func decode<T: Decodable>(_ type: T.Type,
                              from postgresValues: [PostgresValue],
                              defaultTimeZone: TimeZone) throws -> T {

        return try T(from: _RowDecoder(outer: self,
                                       postgresValues: postgresValues,
                                       defaultTimeZone: defaultTimeZone))
    }

    // Inner class to hold per-row state.
    private class _RowDecoder: Decoder {
        
        init(outer: RowDecoder, postgresValues: [PostgresValue], defaultTimeZone: TimeZone) {
            self.outer = outer
            self.postgresValues = postgresValues
            self.defaultTimeZone = defaultTimeZone

            assert(outer.inferColumnNames ||
                   outer.columnIndicesByName.count == postgresValues.count)
        }
        
        let outer: RowDecoder
        let postgresValues: [PostgresValue]
        let defaultTimeZone: TimeZone
        
        // Gets the value of the column for the specified key.
        func value<T>(for key: CodingKey) throws -> T {
            
            var index = outer.columnIndicesByName[key.stringValue]
            
            if index == nil {
                guard outer.inferColumnNames &&
                        outer.columnIndicesByName.count < postgresValues.count else {
                    throw DecodingError.keyNotFound(
                        key,
                        DecodingError.Context(
                            codingPath: [ key ],
                            debugDescription: "No column named \(key.stringValue)"))
                }
                
                // Add a new name-to-index mapping.
                index = outer.columnIndicesByName.count
                outer.columnIndicesByName[key.stringValue] = index
            }
            
            let postgresValue = postgresValues[index!]
            
            // If we want a PostgresValue, then return the column's value as is.
            if T.self is PostgresValue.Type {
                return postgresValue as! T
            }

            // Otherwise, if the column's value is null, report an error
            // (Decoder handles optionals through a different code path).
            if postgresValue.isNull {
                throw DecodingError.valueNotFound(
                    T.self,
                    DecodingError.Context(
                        codingPath: [ key ],
                        debugDescription: "Value of column is null"))
            }
            
            // Otherwise, convert the column's value to the requested type, reporting any
            // conversion errors.
            let value: T?
            
            do {
                switch T.self {
                case is Bool.Type: value = try postgresValue.bool() as? T
                case is String.Type: value = try postgresValue.string() as? T
                case is Double.Type: value = try postgresValue.double() as? T
                case is Float.Type: value = try Float(postgresValue.double()) as? T
                case is Int.Type: value = try postgresValue.int() as? T
                case is Int8.Type: value = try Int8(postgresValue.string()) as? T
                case is Int16.Type: value = try Int16(postgresValue.string()) as? T
                case is Int32.Type: value = try Int32(postgresValue.string()) as? T
                case is Int64.Type: value = try Int64(postgresValue.string()) as? T
                case is UInt.Type: value = try UInt(postgresValue.string()) as? T
                case is UInt8.Type: value = try UInt8(postgresValue.string()) as? T
                case is UInt16.Type: value = try UInt16(postgresValue.string()) as? T
                case is UInt32.Type: value = try UInt32(postgresValue.string()) as? T
                case is UInt64.Type: value = try UInt64(postgresValue.string()) as? T

                default:
                    fatalError("Unexpected type: \(T.self)") // can't happen
                }
            } catch {
                throw DecodingError.typeMismatch(
                    T.self,
                    DecodingError.Context(codingPath: [ key ],
                                          debugDescription: "Invalid value: \(postgresValue.rawValue!)",
                                          underlyingError: error))
            }
            
            // Some of these type conversions used optional initializers.  If the coerced value is
            // nil, report a conversion error.
            guard let value = value else {
                throw DecodingError.typeMismatch(
                    T.self,
                    DecodingError.Context(codingPath: [ key ],
                                          debugDescription: "Invalid value: \(postgresValue.rawValue!)"))
            }
            
            return value
        }
        

        //
        // MARK: Decoder conformance
        //

        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:] // not used by this Decoder
        
        func container<Key>(keyedBy type: Key.Type) throws
            -> KeyedDecodingContainer<Key> where Key: CodingKey {
                
            return KeyedDecodingContainer(RowKeyedDecodingContainer(decoder: self))
        }
                
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Unkeyed containers not supported"))
        }
        
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            return RowSingleValueDecodingContainer(decoder: self)
        }
        
        struct RowKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
            
            let decoder: _RowDecoder
            
            var outer: RowDecoder {
                decoder.outer
            }
            
            var codingPath: [CodingKey] {
                decoder.codingPath
            }
            
            var allKeys: [Key] {
                // When decoding by column index, we can only return "all known keys".
                // In any case, this method doesn't appear to ever get called.
                outer.columnIndicesByName.keys.compactMap { Key(stringValue: $0) }
            }
            
            func contains(_ key: Key) -> Bool {
                // When decoding by column index, we return true if we're prepared to add a new
                // name-to-index mapping, even if we haven't heard of this column name until now.
                return outer.columnIndicesByName[key.stringValue] != nil ||
                    (outer.inferColumnNames &&
                     outer.columnIndicesByName.count < decoder.postgresValues.count)
            }
            
            func value<T>(for key: Key) throws -> T {
                guard codingPath.isEmpty else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: codingPath,
                                              debugDescription: "Nested containers not supported"))
                }
                
                return try decoder.value(for: key)
            }
            
            func decodeNil(forKey key: Key) throws -> Bool {
                return try (value(for: key) as PostgresValue).isNull
            }
            
            func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
                return try value(for: key)
            }
            
            func decode(_ type: String.Type, forKey key: Key) throws -> String {
                return try value(for: key)
            }
            
            func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
                return try value(for: key)
            }
            
            func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
                return try value(for: key)
            }
            
            func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
                return try value(for: key)
            }
            
            func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
                return try value(for: key)
            }
            
            func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
                return try value(for: key)
            }
            
            func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
                return try value(for: key)
            }
            
            func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
                return try value(for: key)
            }
            
            func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
                return try value(for: key)
            }
            
            func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
                return try value(for: key)
            }
            
            func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
                return try value(for: key)
            }
            
            func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
                return try value(for: key)
            }
            
            func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
                return try value(for: key)
            }
            
            func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
                
                if type == Date.self {
                    // For Foundation Dates, we override the default Decodable implementation
                    // and try converting the PostgresValue to each of the 5 PostgresClientKit
                    // types for dates/times.  Three of these conversions also require the API
                    // consumer to supply a TimeZone to use.
                    let postgresValue: PostgresValue = try value(for: key)
                    
                    let value: T? =
                        (try? postgresValue.timestampWithTimeZone().date as? T) ??
                        (try? postgresValue.timestamp().date(in: decoder.defaultTimeZone) as? T) ??
                        (try? postgresValue.date().date(in: decoder.defaultTimeZone) as? T) ??
                        (try? postgresValue.time().date(in: decoder.defaultTimeZone) as? T) ??
                        (try? postgresValue.timeWithTimeZone().date as? T)
                    
                    guard let value = value else {
                        throw DecodingError.typeMismatch(
                            T.self,
                            DecodingError.Context(
                                codingPath: [ key ],
                                debugDescription: "Invalid value: \(postgresValue.rawValue!)"))
                    }
                    
                    return value
                } else {
                    // For any other type, delegate to that type's Decodable implementation.
                    decoder.codingPath += [ key ]
                    defer { decoder.codingPath.removeLast() }
                    return try T(from: decoder)
                }
            }
            
            func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
                -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
                    
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Nested containers not supported"))
            }
            
            func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Nested containers not supported"))
            }
            
            func superDecoder() throws -> Decoder {
                return decoder
            }
            
            func superDecoder(forKey key: Key) throws -> Decoder {
                return decoder
            }
        }
        
        struct RowSingleValueDecodingContainer: SingleValueDecodingContainer {

            let decoder: _RowDecoder
            
            var codingPath: [CodingKey] {
                decoder.codingPath
            }
            
            func value<T>() throws -> T {
                guard let key = codingPath.last else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: codingPath,
                            debugDescription: "SingleValueDecodingContainer requires codingPath"))
                }
                
                return try decoder.value(for: key)
            }
            
            func decodeNil() -> Bool {
                let column: PostgresValue? = try? value() // this function doesn't throw
                return column?.isNull ?? false
            }
            
            func decode(_ type: Bool.Type) throws -> Bool {
                return try value()
            }
            
            func decode(_ type: String.Type) throws -> String {
                return try value()
            }
            
            func decode(_ type: Double.Type) throws -> Double {
                return try value()
            }
            
            func decode(_ type: Float.Type) throws -> Float {
                return try value()
            }
            
            func decode(_ type: Int.Type) throws -> Int {
                return try value()
            }
            
            func decode(_ type: Int8.Type) throws -> Int8 {
                return try value()
            }
            
            func decode(_ type: Int16.Type) throws -> Int16 {
                return try value()
            }
            
            func decode(_ type: Int32.Type) throws -> Int32 {
                return try value()
            }
            
            func decode(_ type: Int64.Type) throws -> Int64 {
                return try value()
            }
            
            func decode(_ type: UInt.Type) throws -> UInt {
                return try value()
            }
            
            func decode(_ type: UInt8.Type) throws -> UInt8 {
                return try value()
            }
            
            func decode(_ type: UInt16.Type) throws -> UInt16 {
                return try value()
            }
            
            func decode(_ type: UInt32.Type) throws -> UInt32 {
                return try value()
            }
            
            func decode(_ type: UInt64.Type) throws -> UInt64 {
                return try value()
            }
            
            func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
                return try T(from: decoder)
            }
        }
    }
}

// EOF
