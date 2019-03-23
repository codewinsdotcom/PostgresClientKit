//
//  Value.swift
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

public struct Value: ValueConvertible, CustomStringConvertible {
    
    public init(_ rawValue: String?) {
        self.rawValue = rawValue
    }
    
    internal let rawValue: String?
    
    private func verifyNotNil() throws {
        if rawValue == nil {
            throw PostgresError.valueIsNil
        }
    }
    
    private func conversionError(_ type: Any.Type) -> Error {
        return PostgresError.valueConversionError(value: self, type: type)
    }

    
    //
    // MARK: ValueConvertible
    //
    
    public var postgresValue: Value {
        return self
    }
    

    //
    // MARK: CustomStringConvertible
    //
    
    public var description: String {
        return rawValue == nil ?
            "nil" :
            String(describing: rawValue!)
    }
}


//
// MARK: String
//

public extension Value {
    
    public func string() throws -> String {
        try verifyNotNil()
        return try optionalString()!
    }
    
    public func optionalString() throws -> String? {
        return rawValue
    }
}

extension String: ValueConvertible {
    public var postgresValue: Value {
        return Value(self)
    }
}


//
// MARK: Int
//

public extension Value {
    
    public func int() throws -> Int {
        try verifyNotNil()
        return try optionalInt()!
    }

    public func optionalInt() throws -> Int? {
        guard let rawValue = rawValue else { return nil }
        guard let v = Int(rawValue) else { throw conversionError(Int.self) }
        return v
    }
}

extension Int: ValueConvertible {
    public var postgresValue: Value {
        return Value(String(describing: self))
    }
}


//
// MARK: Double
//

public extension Value {
    
    public func double() throws -> Double {
        try verifyNotNil()
        return try optionalDouble()!
    }
    
    public func optionalDouble() throws -> Double? {
        guard let rawValue = rawValue else { return nil }
        guard let v = Double(rawValue) else { throw conversionError(Double.self) }
        return v
    }
}

extension Double: ValueConvertible {
    public var postgresValue: Value {
        return Value(String(describing: self))
    }
}


//
// MARK: Decimal
//

public extension Value {
    
    public func decimal() throws -> Decimal {
        try verifyNotNil()
        return try optionalDecimal()!
    }
    
    public func optionalDecimal() throws -> Decimal? {
        
        guard let rawValue = rawValue else { return nil }
        
        guard let v = Decimal(string: rawValue, locale: Postgres.enUsPosixLocale) else {
            throw conversionError(Decimal.self)
        }
        
        return v
    }
}

extension Decimal: ValueConvertible {
    public var postgresValue: Value {
        return Value(String(describing: self))
    }
}


//
// MARK: Boolean
//

public extension Value {
    
    public func bool() throws -> Bool {
        try verifyNotNil()
        return try optionalBool()!
    }
    
    public func optionalBool() throws -> Bool? {
        
        guard let rawValue = rawValue else { return nil }
        
        // https://www.postgresql.org/docs/11/datatype-boolean.html
        switch rawValue {
        case "t": return true
        case "f": return false
        default: throw conversionError(Bool.self)
        }
    }
}

extension Bool: ValueConvertible {
    public var postgresValue: Value {
        return Value(self ? "t" : "f")
    }
}

// EOF
