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
public struct PostgresByteA: PostgresValueConvertible, CustomStringConvertible {
    
    /// Creates a PostgresByteA from the specified `Data`.
    ///
    /// - Parameter data: the data
    public init(data: Data) {
        self.data = data
    }
    
    /// Creates a PostgresByteA from the specified hex format string.
    ///
    /// The Postgres hex format encodes binary data as `\x` followed by two hex digits per byte,
    /// most significant nibble first.  Hex digits `a` to `f` can be uppercase or lowercase.
    ///
    /// - Parameter hexEncoded: the hex format string
    public init?(_ hexEncoded: String) {
        
        guard hexEncoded.hasPrefix("\\x") else {
            return nil
        }
        
        let hexEncoded = hexEncoded[hexEncoded.index(
            hexEncoded.startIndex, offsetBy: "\\x".count)...]
        
        guard let data = PostgresByteA.hexEncodedStringToData(hexEncoded) else {
            return nil
        }
        
        self.init(data: data)
    }
    
    /// The `BYTEA` value, as a `Data`.
    public let data: Data
    
    
    //
    // MARK: PostgresValueConvertible
    //
    
    /// A `PostgresValue` for this PostgresByteA.
    public var postgresValue: PostgresValue {
        return PostgresValue(PostgresByteA.dataToHexEncodedString(data, prefix: "\\x"))
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that describes this PostgresByteA.
    public var description: String {
        return "PostgresByteA(count=\(data.count))"
    }
    
    
    //
    // MARK: Implementation
    //
    
    private static let hexDigitToChar = Array("0123456789abcdef".utf8)
    
    private static func dataToHexEncodedString(_ data: Data, prefix: String) -> String {
        
        var hexEncoded = Array(prefix.utf8)
        hexEncoded.reserveCapacity(hexEncoded.count + data.count * 2)
        
        for byte in data {
            let i = Int(byte)
            hexEncoded.append(hexDigitToChar[i / 16])
            hexEncoded.append(hexDigitToChar[i % 16])
        }
        
        return String(bytes: hexEncoded, encoding: .utf8)!
    }
    
    private static let charToHexDigit: [UInt8] = {
        
        var map = [UInt8](repeating: 0xff, count: 256)
        
        for i in 0x00...0x09 {
            map[0x30 + i] = UInt8(i)        // "0" to "9"
        }
        
        for i in 0x0a...0x0f {
            map[0x41 - 0x0a + i] = UInt8(i) // "A" to "F"
            map[0x61 - 0x0a + i] = UInt8(i) // "a" to "f"
        }
        
        return map
    }()
    
    private static func hexEncodedStringToData<T: StringProtocol>(_ hex: T) -> Data? {
        
        let utf8 = Array(hex.utf8)
        guard utf8.count % 2 == 0 else { return nil }
        
        var bytes = [UInt8]()
        bytes.reserveCapacity(utf8.count / 2)
        
        for i in stride(from: 0, to: utf8.count, by: 2) {
            let hi = charToHexDigit[Int(utf8[i])]
            let lo = charToHexDigit[Int(utf8[i + 1])]
            guard hi != 0xff && lo != 0xff else { return nil }
            bytes.append(hi << 4 | lo)
        }
        
        return Data(bytes)
    }
}

// EOF
