//
//  PostgresByteA.swift
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

/// Represents a Postgres `BYTEA` value (a byte array).
public struct PostgresByteA: PostgresValueConvertible, Equatable, CustomStringConvertible {
    
    /// Creates a `PostgresByteA` from the specified `Data`.
    ///
    /// - Parameter data: the data
    public init(data: Data) {
        self.data = data
    }
    
    /// Creates a `PostgresByteA` from the specified hex format string.
    ///
    /// The Postgres hex format encodes binary data as `\x` followed by two hex digits per byte,
    /// most significant nibble first.  Hex digits `a` to `f` can be uppercase or lowercase.
    ///
    /// - Parameter hexEncoded: the hex format string
    public init?(_ hexEncoded: String) {
        
        guard hexEncoded.hasPrefix("\\x") else {
            return nil
        }
        
        let hexEncoded = String(
            hexEncoded[hexEncoded.index(hexEncoded.startIndex, offsetBy: "\\x".count)...])
        
        guard let data = Data(hexEncoded: hexEncoded) else {
            return nil
        }
        
        self.init(data: data)
    }
    
    /// The `BYTEA` value, as a `Data`.
    public let data: Data
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this `PostgresByteA.`
    public var postgresValue: PostgresValue {
        return PostgresValue(data.hexEncodedString(prefix: "\\x"))
    }
    
    
    //
    // MARK: Equatable
    //
    
    /// True if `lhs.data == rhs.data`.
    public static func == (lhs: PostgresByteA, rhs: PostgresByteA) -> Bool {
        return lhs.data == rhs.data
    }

    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that describes this `PostgresByteA`.
    public var description: String {
        return "PostgresByteA(count=\(data.count))"
    }
}

// EOF
