//
//  CryptoTest.swift
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

@testable import PostgresClientKit
import XCTest

/// Tests Crypto.
class CryptoTest: PostgresClientKitTestCase {
    
    let includeSlowerTestCases = false
    
    func testMD5() {
        
        func md5(message: String, expectedDigest: String) {
            let data = Data(message.utf8)
            let digest = Crypto.md5(data: data).hexEncodedString()
            XCTAssertEqual(digest, expectedDigest)
        }
        
        // Test vectors from RFC 1321 Appendix A.5.
        md5(message: "",
            expectedDigest: "d41d8cd98f00b204e9800998ecf8427e")
        
        md5(message: "a",
            expectedDigest: "0cc175b9c0f1b6a831c399e269772661")
        
        md5(message: "abc",
            expectedDigest: "900150983cd24fb0d6963f7d28e17f72")
        
        md5(message: "message digest",
            expectedDigest: "f96b697d7cb7938d525a2f31aaf161d0")
        
        md5(message: "abcdefghijklmnopqrstuvwxyz",
            expectedDigest: "c3fcd3d76192e4007dfb496cca67e13b")
        
        md5(message: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
            expectedDigest: "d174ab98d277d9f5a5611c2c9f419d9f")
        
        md5(message: "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
            expectedDigest: "57edf4a22be3c955ac49da2e2107b67a")
    }
    
    func testSHA256() {
        
        func sha256(message: String, expectedDigest: String) {
            let data = Data(message.utf8)
            let digest = Crypto.sha256(data: data).hexEncodedString()
            XCTAssertEqual(digest, expectedDigest)
        }
        
        // Test vectors from https://www.di-mgt.com.au/sha_testvectors.html.
        sha256(message: "abc",
               expectedDigest: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        
        sha256(message: "",
               expectedDigest: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        
        sha256(message: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
               expectedDigest: "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        
        sha256(message: "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
               expectedDigest: "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")

        if includeSlowerTestCases {
            sha256(message: String(repeating: "a",
                                   count: 1_000_000),
                   expectedDigest: "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
            
            sha256(message: String(repeating: "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmno",
                                   count: 16_777_216),
                   expectedDigest: "50e72a0e26442fe2552dc3938ac58658228c0cbfb1d2ca872ae435266fcd055e")
        }
    }
    
    func testHMACSHA256() {
        
        func testHMACSHA256(key: Data, message: Data, expectedDigest: String) {
            let data = Crypto.hmacSHA256(key: key, message: message)
            let digest = data.hexEncodedString()
            XCTAssertEqual(digest, expectedDigest)
        }

        // Test vectors from RFC 4231
        testHMACSHA256(
            key: Data(hexEncoded:
                """
                0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b\
                0b0b0b0b
                """)!,
            message: Data(hexEncoded:
                """
                4869205468657265
                """)!,
            expectedDigest:
                """
                b0344c61d8db38535ca8afceaf0bf12b\
                881dc200c9833da726e9376c2e32cff7
                """)
        
        testHMACSHA256(
            key: Data(hexEncoded:
                """
                4a656665
                """)!,
            message: Data(hexEncoded:
                """
                7768617420646f2079612077616e7420\
                666f72206e6f7468696e673f
                """)!,
            expectedDigest:
                """
                5bdcc146bf60754e6a042426089575c7\
                5a003f089d2739839dec58b964ec3843
                """)
        
        testHMACSHA256(
            key: Data(hexEncoded:
                """
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaa
                """)!,
            message: Data(hexEncoded:
                """
                dddddddddddddddddddddddddddddddd\
                dddddddddddddddddddddddddddddddd\
                dddddddddddddddddddddddddddddddd\
                dddd
                """)!,
            expectedDigest:
                """
                773ea91e36800e46854db8ebd09181a7\
                2959098b3ef8c122d9635514ced565fe
                """)
        
        testHMACSHA256(
            key: Data(hexEncoded:
                """
                0102030405060708090a0b0c0d0e0f10\
                111213141516171819
                """)!,
            message: Data(hexEncoded:
                """
                cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd\
                cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd\
                cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd\
                cdcd
                """)!,
            expectedDigest:
                """
                82558a389a443c0ea4cc819899f2083a\
                85f0faa3e578f8077a2e3ff46729665b
                """)
        
        testHMACSHA256(
            key: Data(hexEncoded:
                """
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaa
                """)!,
            message: Data(hexEncoded:
                """
                54657374205573696e67204c61726765\
                72205468616e20426c6f636b2d53697a\
                65204b6579202d2048617368204b6579\
                204669727374
                """)!,
            expectedDigest:
                """
                60e431591ee0b67f0d8a26aacbf5b77f\
                8e0bc6213728c5140546040f0ee37f54
                """)

        testHMACSHA256(
            key: Data(hexEncoded:
                """
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\
                aaaaaa
                """)!,
            message: Data(hexEncoded:
                """
                54686973206973206120746573742075\
                73696e672061206c6172676572207468\
                616e20626c6f636b2d73697a65206b65\
                7920616e642061206c61726765722074\
                68616e20626c6f636b2d73697a652064\
                6174612e20546865206b6579206e6565\
                647320746f2062652068617368656420\
                6265666f7265206265696e6720757365\
                642062792074686520484d414320616c\
                676f726974686d2e
                """)!,
            expectedDigest:
                """
                9b09ffa71b942fcb27635fbcd5b0e944\
                bfdc63644f0713938a7f51535c3a35e2
                """)
    }
    
    func testPBKDF2HMACSHA256() {
        
        func testPBKDF2HMACSHA256(password: Data,
                                 salt: Data,
                                 iterationCount: Int,
                                 expectedKey: String) {
            
            let keyData = Crypto.pbkdf2HMACSHA256(password: password,
                                             salt: salt,
                                             iterationCount: iterationCount)
            let key = keyData.hexEncodedString()
            XCTAssertEqual(key, expectedKey)

            // Also test pure Swift implementation for a subset of test cases.
            if iterationCount <= 256 {
                let keyData = Crypto.pbkdf2HMACSHA256Swift(password: password,
                                                      salt: salt,
                                                      iterationCount: iterationCount)
                let key = keyData.hexEncodedString()
                XCTAssertEqual(key, expectedKey)
            }
            
            XCTAssertEqual(key, expectedKey)
        }
        
        // Test vectors from https://stackoverflow.com/questions/5130513/pbkdf2-hmac-sha2-test-vectors
        testPBKDF2HMACSHA256(
            password: Data("password".utf8),
            salt: Data("salt".utf8),
            iterationCount: 1,
            expectedKey:
                """
                120fb6cffcf8b32c\
                43e7225256c4f837\
                a86548c92ccc3548\
                0805987cb70be17b
                """)
        
        testPBKDF2HMACSHA256(
            password: Data("password".utf8),
            salt: Data("salt".utf8),
            iterationCount: 2,
            expectedKey:
                """
                ae4d0c95af6b46d3\
                2d0adff928f06dd0\
                2a303f8ef3c251df\
                d6e2d85a95474c43
                """)
        
        testPBKDF2HMACSHA256(
            password: Data("password".utf8),
            salt: Data("salt".utf8),
            iterationCount: 4096,
            expectedKey:
                """
                c5e478d59288c841\
                aa530db6845c4c8d\
                962893a001ce4e11\
                a4963873aa98134a
                """)

        testPBKDF2HMACSHA256(
            password: Data("password".utf8),
            salt: Data("salt".utf8),
            iterationCount: 16777216,
            expectedKey:
                """
                cf81c66fe8cfc04d\
                1f31ecb65dab4089\
                f7f179e89b3b0bcb\
                17ad10e3ac6eba46
                """)

        testPBKDF2HMACSHA256(
            password: Data("passwordPASSWORDpassword".utf8),
            salt: Data("saltSALTsaltSALTsaltSALTsaltSALTsalt".utf8),
            iterationCount: 4096,
            expectedKey:
                """
                348c89dbcbd32b2f\
                32d814b8116e84cf\
                2b17347ebc180018\
                1c4e2a1fb8dd53e1
                """)

        testPBKDF2HMACSHA256(
            password: Data("pass\0word".utf8),
            salt: Data("sa\0lt".utf8),
            iterationCount: 4096,
            expectedKey:
                """
                89b69d0516f82989\
                3c696226650a8687\
                8c029ac13ee27650\
                9d5ae58b6466a724
                """)
    }
}

// EOF
