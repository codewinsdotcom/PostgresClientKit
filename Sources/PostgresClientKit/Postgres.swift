//
//  Postgres.swift
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

/// A namespace for properties and methods used throughout PostgresClientKit.
public struct Postgres {
    
    //
    // MARK: Logging
    //
    
    /// The logger used by PostgresClientKit.
    public static let logger = Logger()


    //
    // MARK: ID generation
    //
    
    /// A threadsafe counter that starts with 1 and increments by 1 with each invocation.
    internal static func nextId() -> UInt64 {
        nextIdSemaphore.wait()
        defer { nextIdSemaphore.signal() }
        let id = _nextId
        _nextId &+= 1 // wraparound
        return id
    }
    
    private static let nextIdSemaphore = DispatchSemaphore(value: 1)
    private static var _nextId: UInt64 = 1
    
    
    //
    // MARK: Localization
    //
    
    /// The `en_US_POSIX` locale.
    internal static let enUsPosixLocale = Locale(identifier: "en_US_POSIX")
}


//
// MARK: Type conversion extensions
//

internal extension UInt16 {
    
    /// The big-endian representation.
    var data: Data {
        var value = bigEndian
        return Data(bytes: &value, count: 2)
    }
}

internal extension UInt32 {
    
    /// The big-endian representation.
    var data: Data {
        var value = bigEndian
        return Data(bytes: &value, count: 4)
    }
}

internal extension UInt64 {
    
    var data: Data {
        var value = bigEndian
        return Data(bytes: &value, count: 8)
    }
}

internal extension String {
    
    /// The UTF8 representation.
    var data: Data {
        return Data(utf8)
    }
    
    /// The null-terminated UTF8 representation.
    var dataZero: Data {
        var data = self.data
        data.append(0)
        return data
    }
}

internal extension Data {
    
    init?(hexEncoded: String) {
        
        let utf8 = Array(hexEncoded.utf8)
        guard utf8.count % 2 == 0 else { return nil }
        
        var bytes = [UInt8]()
        bytes.reserveCapacity(utf8.count / 2)
        
        for i in stride(from: 0, to: utf8.count, by: 2) {
            let hi = Data.charToHexDigit[Int(utf8[i])]
            let lo = Data.charToHexDigit[Int(utf8[i + 1])]
            guard hi != 0xff && lo != 0xff else { return nil }
            bytes.append(hi << 4 | lo)
        }
        
        self.init(bytes)
    }
    
    func hexEncodedString(prefix: String = "") -> String {
        
        var hexEncoded = Array(prefix.utf8)
        hexEncoded.reserveCapacity(hexEncoded.count + count * 2)
        
        for byte in self {
            let i = Int(byte)
            hexEncoded.append(Data.hexDigitToChar[i / 16])
            hexEncoded.append(Data.hexDigitToChar[i % 16])
        }
        
        return String(bytes: hexEncoded, encoding: .utf8)!
    }

    private static let hexDigitToChar = Array("0123456789abcdef".utf8)
    
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
}

// EOF
