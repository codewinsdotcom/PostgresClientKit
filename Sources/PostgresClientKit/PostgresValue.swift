//
//  PostgresValue.swift
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

/// A value to be sent to or returned from the Postgres server.
///
/// PostgresClientKit extends standard Swift types to conform to the `PostgresValueConvertible`
/// protocol, making it easy to convert instances of those types to `PostgresValue`.  For example:
///
///     // Convert String to PostgresValue.
///     let greeting = "Hello, world!"
///     let greetingValue = greeting.postgresValue
///
///     // Convert Double to PostgresValue.
///     let pi = 3.14
///     let piValue = pi.postgresValue
///
///     // Convert an optional Int to PostgresValue.
///     let score: Int? = nil
///     let scoreValue = score.postgresValue
///
/// Use `PostgresValue` methods to convert `PostgresValue` instances back to standard Swift types.
/// These methods throw errors if the conversion fails.
///
///     try greetingValue.string()      // "Hello, world!"
///     try greetingValue.int()         // throws PostgresError.valueConversionError
///
///     try piValue.double()            // 3.14
///     try piValue.string()            // "3.14"
///
///     try scoreValue.optionalInt()    // nil
///     try scoreValue.int()            // throws PostgresError.valueIsNil
///
public struct PostgresValue: PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresValue` from the raw value used in the Postgres network protocol.
    ///
    /// - Parameter rawValue: the raw value, or `nil` to represent a SQL `NULL` value
    public init(_ rawValue: String?) {
        self.rawValue = rawValue
    }
    
    /// The raw value used in the Postgres network protocol, or `nil` to represent a SQL `NULL`
    /// value.
    public let rawValue: String?
    
    /// Whether this `PostgresValue` represents a SQL `NULL` value.
    public var isNull: Bool {
        return rawValue == nil
    }
    
    private func verifyNotNil() throws {
        if isNull {
            throw PostgresError.valueIsNil
        }
    }
    
    private func conversionError(_ type: Any.Type) -> Error {
        return PostgresError.valueConversionError(value: self, type: type)
    }
}


//
// MARK: String
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `String`.
    ///
    /// - Returns: the `String`
    /// - Throws: `PostgresError` if the conversion fails
    func string() throws -> String {
        try verifyNotNil()
        return try optionalString()!
    }
    
    /// Converts this `PostgresValue` to an optional `String`.
    ///
    /// - Returns: the optional `String`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalString() throws -> String? {
        return rawValue
    }
}

extension String: PostgresValueConvertible {
    
    /// A `PostgresValue` for this `String`.
    public var postgresValue: PostgresValue {
        return PostgresValue(self)
    }
}


//
// MARK: Int
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to an `Int`.
    ///
    /// - Returns: the `Int`
    /// - Throws: `PostgresError` if the conversion fails
    func int() throws -> Int {
        try verifyNotNil()
        return try optionalInt()!
    }

    /// Converts this `PostgresValue` to an optional `Int`.
    ///
    /// - Returns: the optional `Int`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalInt() throws -> Int? {
        guard let rawValue = rawValue else { return nil }
        guard let v = Int(rawValue) else { throw conversionError(Int.self) }
        return v
    }
}

extension Int: PostgresValueConvertible {
    
    /// A `PostgresValue` for this `Int`.
    public var postgresValue: PostgresValue {
        return PostgresValue(String(describing: self))
    }
}


//
// MARK: Double
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `Double`.
    ///
    /// - Returns: the `Double`
    /// - Throws: `PostgresError` if the conversion fails
    func double() throws -> Double {
        try verifyNotNil()
        return try optionalDouble()!
    }
    
    /// Converts this `PostgresValue` to an optional `Double`.
    ///
    /// - Returns: the optional `Double`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalDouble() throws -> Double? {
        guard let rawValue = rawValue else { return nil }
        guard let v = Double(rawValue) else { throw conversionError(Double.self) }
        return v
    }
}

extension Double: PostgresValueConvertible {
    
    /// A `PostgresValue` for this `Double`.
    public var postgresValue: PostgresValue {
        return PostgresValue(String(describing: self))
    }
}


//
// MARK: Decimal
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `Decimal`.
    ///
    /// - Returns: the `Decimal`
    /// - Throws: `PostgresError` if the conversion fails
    func decimal() throws -> Decimal {
        try verifyNotNil()
        return try optionalDecimal()!
    }
    
    /// Converts this `PostgresValue` to an optional `Decimal`.
    ///
    /// - Returns: the optional `Decimal`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalDecimal() throws -> Decimal? {
        
        guard let rawValue = rawValue else { return nil }
        
        if rawValue.lowercased() == "nan" { return Decimal.nan }
        
        guard let v = Decimal(string: rawValue, locale: Postgres.enUsPosixLocale) else {
            throw conversionError(Decimal.self)
        }
        
        return v
    }
}

extension Decimal: PostgresValueConvertible {
    
    /// A `PostgresValue` for this `Decimal`.
    public var postgresValue: PostgresValue {
        return PostgresValue(String(describing: self))
    }
}


//
// MARK: Bool
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `Bool`.
    ///
    /// - Returns: the `Bool`
    /// - Throws: `PostgresError` if the conversion fails
    func bool() throws -> Bool {
        try verifyNotNil()
        return try optionalBool()!
    }
    
    /// Converts this `PostgresValue` to an optional `Bool`
    ///
    /// - Returns: the optional `Bool`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalBool() throws -> Bool? {
        
        guard let rawValue = rawValue else { return nil }
        
        // https://www.postgresql.org/docs/12/datatype-boolean.html
        switch rawValue {
        case "t": return true
        case "f": return false
        default: throw conversionError(Bool.self)
        }
    }
}

extension Bool: PostgresValueConvertible {
    
    /// A `PostgresValue` for this `Bool`.
    public var postgresValue: PostgresValue {
        return PostgresValue(self ? "t" : "f")
    }
}


//
// MARK: PostgresTimestampWithTimeZone
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresTimestampWithTimeZone`.
    ///
    /// - Returns: the `PostgresTimestampWithTimeZone`
    /// - Throws: `PostgresError` if the conversion fails
    func timestampWithTimeZone() throws -> PostgresTimestampWithTimeZone {
        try verifyNotNil()
        return try optionalTimestampWithTimeZone()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresTimestampWithTimeZone`.
    ///
    /// - Returns: the optional `PostgresTimestampWithTimeZone`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalTimestampWithTimeZone() throws -> PostgresTimestampWithTimeZone? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let timestampWithTimeZone = PostgresTimestampWithTimeZone(rawValue) else {
            throw conversionError(PostgresTimestampWithTimeZone.self)
        }
        
        return timestampWithTimeZone
    }
}


//
// MARK: PostgresTimestamp
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresTimestamp`.
    ///
    /// - Returns: the `PostgresTimestamp`
    /// - Throws: `PostgresError` if the conversion fails
    func timestamp() throws -> PostgresTimestamp {
        try verifyNotNil()
        return try optionalTimestamp()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresTimestamp`.
    ///
    /// - Returns: the optional `PostgresTimestamp`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalTimestamp() throws -> PostgresTimestamp? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let timestamp = PostgresTimestamp(rawValue) else {
            throw conversionError(PostgresTimestamp.self)
        }
        
        return timestamp
    }
}


//
// MARK: PostgresDate
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresDate`.
    ///
    /// - Returns: the `PostgresDate`
    /// - Throws: `PostgresError` if the conversion fails
    func date() throws -> PostgresDate {
        try verifyNotNil()
        return try optionalDate()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresDate`.
    ///
    /// - Returns: the optional `PostgresDate`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalDate() throws -> PostgresDate? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let date = PostgresDate(rawValue) else {
            throw conversionError(PostgresDate.self)
        }
        
        return date
    }
}


//
// MARK: PostgresTime
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresTime`.
    ///
    /// - Returns: the `PostgresTime`
    /// - Throws: `PostgresError` if the conversion fails
    func time() throws -> PostgresTime {
        try verifyNotNil()
        return try optionalTime()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresTime`.
    ///
    /// - Returns: the optional `PostgresTime`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalTime() throws -> PostgresTime? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let time = PostgresTime(rawValue) else {
            throw conversionError(PostgresTime.self)
        }
        
        return time
    }
}


//
// MARK: PostgresTimeWithTimeZone
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresTimeWithTimeZone`.
    ///
    /// - Returns: the `PostgresTimeWithTimeZone`
    /// - Throws: `PostgresError` if the conversion fails
    func timeWithTimeZone() throws -> PostgresTimeWithTimeZone {
        try verifyNotNil()
        return try optionalTimeWithTimeZone()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresTimeWithTimeZone`.
    ///
    /// - Returns: the optional `PostgresTimeWithTimeZone`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalTimeWithTimeZone() throws -> PostgresTimeWithTimeZone? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let timeWithTimeZone = PostgresTimeWithTimeZone(rawValue) else {
            throw conversionError(PostgresTimeWithTimeZone.self)
        }
        
        return timeWithTimeZone
    }
}


//
// MARK: PostgresByteA
//

public extension PostgresValue {
    
    /// Converts this `PostgresValue` to a `PostgresByteA`.
    ///
    /// - Returns: the `PostgresByteA`
    /// - Throws: `PostgresError` if the conversion fails
    func byteA() throws -> PostgresByteA {
        try verifyNotNil()
        return try optionalByteA()!
    }
    
    /// Converts this `PostgresValue` to an optional `PostgresByteA`.
    ///
    /// - Returns: the optional `PostgresByteA`
    /// - Throws: `PostgresError` if the conversion fails
    func optionalByteA() throws -> PostgresByteA? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let byteA = PostgresByteA(rawValue) else {
            throw conversionError(PostgresByteA.self)
        }
        
        return byteA
    }
}


//
// MARK: PostgresValueConvertible
//

public extension PostgresValue {
    
    /// The `PostgresValue` itself.
    var postgresValue: PostgresValue {
        return self
    }
}


//
// MARK: Equatable
//

public extension PostgresValue {
    
    /// True if `lhs.rawValue == rhs.rawValue`.
    static func == (lhs: PostgresValue, rhs: PostgresValue) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}


//
// MARK: CustomStringConvertible
//

public extension PostgresValue {
    
    /// A short string that describes this `PostgresValue`.
    var description: String {
        return rawValue == nil ?
            "nil" :
            String(describing: rawValue!)
    }
}


//
// MARK: Optional
//

extension Optional: PostgresValueConvertible where Wrapped: PostgresValueConvertible {
    
    /// A `PostgresValue` for this instance.
    public var postgresValue: PostgresValue {
        switch self {
        case .none: return PostgresValue(nil)
        case let .some(wrapped): return wrapped.postgresValue
        }
    }
}

// EOF
