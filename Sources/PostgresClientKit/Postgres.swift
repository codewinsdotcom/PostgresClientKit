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
    // MARK: Crypto
    //
    
    /// Computes an MD5 digest.
    ///
    /// - SeeAlso: [Wikipedia](https://en.wikipedia.org/wiki/MD5)
    ///
    /// - Parameter data: the input data
    /// - Returns: the 16-byte digest
    internal static func md5(data: Data) -> Data {
        
        /// The per-round shift amounts.
        let s: [UInt32] = [
            7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
            5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
            4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
            6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21 ]
        
        /// Constants derived from the binary integer part of the sines of integers (radians).
        let k: [UInt32] = [
            0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
            0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
            0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
            0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
            0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
            0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
            0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
            0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
            0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
            0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
            0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
            0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
            0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
            0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
            0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
            0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 ]
        
        // Initialize variables.
        var a0: UInt32 = 0x67452301
        var b0: UInt32 = 0xefcdab89
        var c0: UInt32 = 0x98badcfe
        var d0: UInt32 = 0x10325476
        
        // Pre-processing: add a single 1 bit.
        var input = data
        input.append(0x80)
        
        // Pre-processing: pad with zeros until message length in bits is 448 (mod 512).
        input.append(Data(count: (120 - (input.count % 64)) % 64))
        assert(input.count % 64 == 56)
        
        // Append original length in bits mod 2^64 to message.
        var originalLengthInBits = UInt64(data.count * 8).littleEndian
        input.append(Data(bytes: &originalLengthInBits, count: 8))
        
        // Process the message in successive 512-bit chunks.
        for chunk in stride(from: 0, to: input.count, by: 64) {
            
            // Break chunk into sixteen 32-bit words.
            var m = [UInt32]()
            
            for i in 0..<16 {
                let offset = chunk + (4 * i)
                
                m.append(
                    UInt32(input[offset    ]) << 0 |
                        UInt32(input[offset + 1]) << 8 |
                        UInt32(input[offset + 2]) << 16 |
                        UInt32(input[offset + 3]) << 24)
            }
            
            // Initialize hash value for this chunk.
            var a = a0
            var b = b0
            var c = c0
            var d = d0
            
            // Main loop.
            for i in 0..<64 {
                
                var f: UInt32
                var g: Int
                
                switch i {
                case 0..<16:    f = (b & c) | ((~b) & d)    ; g = i
                case 16..<32:   f = (d & b) | ((~d) & c)    ; g = (5 * i + 1) % 16
                case 32..<48:   f = b ^ c ^ d               ; g = (3 * i + 5) % 16
                case 48..<64:   f = c ^ (b | (~d))          ; g = (7 * i) % 16
                default: fatalError() // can't happen
                }
                
                f = f &+ a &+ k[i] &+ m[g]
                a = d
                d = c
                c = b
                b = b &+ ((f << s[i]) | (f >> (32 - s[i])))
            }
            
            // Add this chunk's hash to result so far.
            a0 = a0 &+ a
            b0 = b0 &+ b
            c0 = c0 &+ c
            d0 = d0 &+ d
        }
        
        // Form the output.
        a0 = a0.littleEndian
        b0 = b0.littleEndian
        c0 = c0.littleEndian
        d0 = d0.littleEndian
        
        var output = Data()
        output.append(Data(bytes: &a0, count: 4))
        output.append(Data(bytes: &b0, count: 4))
        output.append(Data(bytes: &c0, count: 4))
        output.append(Data(bytes: &d0, count: 4))
        
        return output
    }
    
    
    //
    // MARK: Localization
    //
    
    /// The `en_US_POSIX` locale.
    internal static let enUsPosixLocale = Locale(identifier: "en_US_POSIX")
    
    /// The UTC/GMT time zone.
    internal static let utcTimeZone = TimeZone(secondsFromGMT: 0)!
    
    #if os(Linux) // temporary workaround for https://bugs.swift.org/browse/SR-10515
    
        /// A calendar based on the `en_US_POSIX` locale and the UTC/GMT time zone.
        internal static var enUsPosixUtcCalendar: Calendar {
            
            let threadDictionary = Thread.current.threadDictionary
            var calendar = threadDictionary["enUsPosixUtcCalendar"] as? Calendar
            
            if calendar == nil {
                calendar = Calendar(identifier: .gregorian)
                calendar!.locale = enUsPosixLocale
                calendar!.timeZone = utcTimeZone
                threadDictionary["enUsPosixUtcCalendar"] = calendar!
            }
            
            calendar!.timeZone = utcTimeZone
            
            return calendar!
        }
    
    #else
    
        /// A calendar based on the `en_US_POSIX` locale and the UTC/GMT time zone.
        internal static let enUsPosixUtcCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = enUsPosixLocale
            calendar.timeZone = utcTimeZone
            return calendar
        }()
    
    #endif
}

// EOF
