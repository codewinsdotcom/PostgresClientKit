//
//  Crypto.swift
//  PostgresClientKit
//
//  Copyright 2020 David Pitfield and the PostgresClientKit contributors
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

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import CommonCrypto
#elseif os(Linux)
    import OpenSSL
#endif

/// Internally used crypto algorithms.
internal struct Crypto {
    
    /// Computes the MD5 digest of the specified message.
    ///
    /// - SeeAlso: [RFC 1321](https://tools.ietf.org/html/rfc1321)
    /// - SeeAlso: [Wikipedia](https://en.wikipedia.org/wiki/MD5)
    ///
    /// - Parameter data: the message
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

    /// Computes the SHA-256 digest of the specified message.
    ///
    /// - SeeAlso: [RFC 6234](https://tools.ietf.org/html/rfc6234)
    ///
    /// - Parameter data: the message; must be less than 2^61 bytes
    /// - Returns: the 32-byte digest
    internal static func sha256(data: Data) -> Data {
        
        // Implementation note:  This method is optimized for code clarity, not performance.
        // It follows RFC 6234 (https://tools.ietf.org/html/rfc6234) in naming and flow.
                
        //
        // Section 3: Operations on words
        //
        
        func SHR(_ n: Int, _ x: UInt32) -> UInt32 {
            return x >> n
        }

        func ROTR(_ n: Int, _ x: UInt32) -> UInt32 {
            return (x >> n) | (x << (32 - n))
        }
        
        
        //
        // Section 4: Message padding and parsing
        //
        
        // SHA-256 is defined for messages whose length is less than 2^64 bits (2^61 bytes).
        precondition(UInt64(data.count) < 1<<61) // 1<<61 == 2^61
        let L = UInt64(data.count * 8) // length in bits
        
        // Add a single 1 bit.
        var data = data
        data.append(0x80)
        
        // Pad with zeros until message length in bits is 448 (mod 512).
        let k = (448 - (Int(L % 512) + 8) + 512) % 512 // (L % 512) prevents overflow
        data.append(Data(count: k / 8))
        assert((data.count * 8) % 512 == 448)
        
        // Append original length of message, in bits.
        data.append(L.data)
        assert((data.count * 8) % 512 == 0)
        
        
        //
        // Section 5: Functions and constants used
        //
        
        func CH(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 {
            return (x & y) ^ (~x & z)
        }
        
        func MAJ(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 {
            return (x & y) ^ (x & z) ^ (y & z)
        }
        
        func BSIG0(_ x: UInt32) -> UInt32 {
            return ROTR(2, x) ^ ROTR(13, x) ^ ROTR(22, x)
        }
        
        func BSIG1(_ x: UInt32) -> UInt32 {
            return ROTR(6, x) ^ ROTR(11, x) ^ ROTR(25, x)
        }

        func SSIG0(_ x: UInt32) -> UInt32 {
            return ROTR(7, x) ^ ROTR(18, x) ^ SHR(3, x)
        }
        
        func SSIG1(_ x: UInt32) -> UInt32 {
            return ROTR(17, x) ^ ROTR(19, x) ^ SHR(10, x)
        }

        let K: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
            0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
            0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
            0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
            0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
            0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
            0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
            0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
            0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 ]

        
        //
        // Section 6.1: Initialization
        //
        
        var h0: UInt32 = 0x6a09e667
        var h1: UInt32 = 0xbb67ae85
        var h2: UInt32 = 0x3c6ef372
        var h3: UInt32 = 0xa54ff53a
        var h4: UInt32 = 0x510e527f
        var h5: UInt32 = 0x9b05688c
        var h6: UInt32 = 0x1f83d9ab
        var h7: UInt32 = 0x5be0cd19
        
        
        //
        // Section 6.2: Processing
        //
        
        // Process the message in successive 512-bit chunks.
        for chunk in stride(from: 0, to: data.count, by: 512 / 8) {
            
            // Prepare the message schedule table.
            var W = [UInt32]()
            
            for t in 0..<16 {
                W.append(
                    UInt32(data[chunk + (4 * t) + 0]) << 24 +
                    UInt32(data[chunk + (4 * t) + 1]) << 16 +
                    UInt32(data[chunk + (4 * t) + 2]) << 8 +
                    UInt32(data[chunk + (4 * t) + 3]))
            }
            
            for t in 16..<64 {
                W.append(SSIG1(W[t-2]) &+ W[t-7] &+ SSIG0(W[t-15]) &+ W[t-16])
            }
            
            // Initialize the working variables.
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            var f = h5
            var g = h6
            var h = h7
            
            // Perform the main hash computation.
            for t in 0..<64 {
                let T1 = h &+ BSIG1(e) &+ CH(e,f,g) &+ K[t] &+ W[t]
                let T2 = BSIG0(a) &+ MAJ(a,b,c)
                h = g
                g = f
                f = e
                e = d &+ T1
                d = c
                c = b
                b = a
                a = T1 &+ T2
            }
            
            // Compute the intermediate hash value.
            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
            h5 = h5 &+ f
            h6 = h6 &+ g
            h7 = h7 &+ h
        }
        
        // Calculate the final output.
        var digest = Data()
        digest.append(h0.data)
        digest.append(h1.data)
        digest.append(h2.data)
        digest.append(h3.data)
        digest.append(h4.data)
        digest.append(h5.data)
        digest.append(h6.data)
        digest.append(h7.data)
        
        return digest
    }
    
    /// Computes the HMAC-SHA-256 value of the specified message.
    ///
    /// - SeeAlso: [RFC 2104](https://tools.ietf.org/html/rfc2104)
    ///
    /// - Parameters:
    ///   - key: the key
    ///   - message: the message
    /// - Returns: the 32-byte HMAC value
    internal static func hmacSHA256(key: Data, message: Data) -> Data {
        
        // Note: for SHA-256, B is 64 bytes, L is 32 bytes.
        
        var key = key
        
        // If the key is longer than 64 bytes, compute its SHA-256 digest and use that as the key.
        if key.count > 64 {
            key = sha256(data: key)
        }
        
        // Zero pad the key to 64 bytes.
        key.append(Data(count: 64 - key.count))
        assert(key.count == 64)
        
        var t1 = Data(key.map { $0 ^ 0x36 })
        t1.append(contentsOf: message)
        t1 = sha256(data: t1)
        
        var t2 = Data(key.map { $0 ^ 0x5c })
        t2.append(t1)
        t2 = sha256(data: t2)

        return t2
    }
    
    /// Derives the PBKDF2-HMAC-SHA56 key for the specified password, salt, and iteration count.
    ///
    /// - SeeAlso: [RFC 2898](https://tools.ietf.org/html/rfc2898)
    ///
    /// - Parameters:
    ///   - password: the password
    ///   - salt: the salt
    ///   - iterationCount: the iteration count
    /// - Returns: the 32-byte PBKDF2 key
    internal static func pbkdf2HMACSHA256(password: Data, salt: Data, iterationCount: Int) -> Data {
        
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        
        // On Apple platforms, use CommonCrypto.  (Using CryptoKit would require macOS 10.15+ or
        // iOS 13+.)
        return pbkdf2HMACSHA256CommonCrypto(password: password, salt: salt, iterationCount: iterationCount)

        #elseif os(Linux)
        
        // On Linux platforms, use OpenSSL.  (OpenSSL is already being brought in by BlueSSLService.
        // Using Swift Crypto would bring in hundreds of source files, as well as require macOS
        // 10.15+ or iOS 13+.)
        return pbkdf2HMACSHA256OpenSSL(password: password, salt: salt, iterationCount: iterationCount)

        #else
        
        // Fallback to pure Swift.  This is slower than CommonCrypo and OpenSSL.
        return pbkdf2HMACSHA256Swift(password: password, salt: salt, iterationCount: iterationCount)
        
        #endif
    }
    
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    private static func pbkdf2HMACSHA256CommonCrypto(password: Data,
                                                    salt: Data,
                                                    iterationCount: Int) -> Data {
        
        var derivedKey = [UInt8](repeating: 0, count: 32)
        
        password.withUnsafeBytes {
            
            let status = CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                $0.baseAddress!.assumingMemoryBound(to: Int8.self),
                password.count,
                [UInt8](salt),
                salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterationCount),
                &derivedKey,
                derivedKey.count)
            
            precondition(status == kCCSuccess, "CCKeyDerivationPBKDF failed with status \(status)")
        }
        
        return Data(derivedKey)
    }
    #endif
    
    #if os(Linux)
    private static func pbkdf2HMACSHA256OpenSSL(password: Data,
                                               salt: Data,
                                               iterationCount: Int) -> Data {
        
        var derivedKey = [UInt8](repeating: 0, count: 32)

        password.withUnsafeBytes {
            
            let status = PKCS5_PBKDF2_HMAC(
                $0.baseAddress!.assumingMemoryBound(to: Int8.self),
                Int32(password.count),
                [UInt8](salt),
                Int32(salt.count),
                Int32(iterationCount),
                EVP_sha256(),
                Int32(derivedKey.count),
                &derivedKey)
            
            precondition(status == 1, "PKCS5_PBKDF2_HMAC failed with status \(status)")
        }
                
        return Data(derivedKey)
    }
    #endif
    
    internal static func pbkdf2HMACSHA256Swift(password: Data,
                                              salt: Data,
                                              iterationCount: Int) -> Data {
        
        var Uprevious = salt
        Uprevious.append(contentsOf: [ 0x00, 0x00, 0x00, 0x01 ])
        
        var Hi = [UInt8]()
        
        for i in 0..<iterationCount {
            let U = hmacSHA256(key: password, message: Uprevious)
            Hi = (i == 0) ? [UInt8](U) : Hi.enumerated().map { $1 ^ U[$0] }
            Uprevious = U
        }
        
        return Data(Hi)
    }
}

// EOF
