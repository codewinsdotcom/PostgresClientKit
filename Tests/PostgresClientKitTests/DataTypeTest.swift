//
//  DataTypeTest.swift
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

import PostgresClientKit
import XCTest

/// Tests roundtripping PostgresValue -> Postgres server data types -> PostgresValue.
class DataTypeTest: PostgresClientKitTestCase {
    
    func test() {
        
        do {
            let connection = try Connection(configuration: terryConnectionConfiguration())
            
            var text = "DROP TABLE IF EXISTS datatypetest"
            try connection.prepareStatement(text: text).execute()
            
            text = """
                CREATE TABLE datatypetest (
                    sequence    integer,
                    cv          character varying(80),
                    c           character(10),
                    i           integer,
                    si          smallint,
                    bi          bigint,
                    dp          double precision,
                    r           real,
                    n           numeric,
                    b           boolean,
                    tstz        timestamp with time zone,
                    ts          timestamp,
                    d           date,
                    t           time,
                    ttz         time with time zone,
                    ba          bytea
                )
                """
            try connection.prepareStatement(text: text).execute()
            
            var lastSequence = 0
            
            func check(_ column: String, _ value: PostgresValueConvertible) {
                
                do {
                    lastSequence += 1
                    
                    var text = "INSERT INTO datatypetest (sequence, \(column)) VALUES ($1, $2)"
                    
                    try connection
                        .prepareStatement(text: text)
                        .execute(parameterValues: [ lastSequence, value ])
                    
                    text = "SELECT \(column) FROM datatypetest WHERE sequence = $1"
                    
                    let readValue = try connection
                        .prepareStatement(text: text)
                        .execute(parameterValues: [ lastSequence ])
                        .next()!.get().columns[0]
                    
                    switch value {
                        
                    case let value as String:
                        XCTAssertEqual(try readValue.string(), value, column)
                        
                    case let value as Int:
                        XCTAssertEqual(try readValue.int(), value, column)
                        
                    case let value as Double:
                        if value.isNaN {
                            XCTAssert(try readValue.double().isNaN, column)
                        } else {
                            XCTAssertEqual(try readValue.double(), value, column)
                        }
                        
                    case let value as Decimal:
                        XCTAssertEqual(try readValue.decimal(), value, column)
                        
                    case let value as Bool:
                        XCTAssertEqual(try readValue.bool(), value, column)
                        
                    case let value as PostgresTimestampWithTimeZone:
                        XCTAssertEqual(try readValue.timestampWithTimeZone(), value, column)
                        
                    case let value as PostgresTimestamp:
                        XCTAssertEqual(try readValue.timestamp(), value, column)
                        
                    case let value as PostgresDate:
                        XCTAssertEqual(try readValue.date(), value, column)
                        
                    case let value as PostgresTime:
                        XCTAssertEqual(try readValue.time(), value, column)
                        
                    case let value as PostgresTimeWithTimeZone:
                        XCTAssertEqual(try readValue.timeWithTimeZone(), value, column)
                        
                    case let value as PostgresByteA:
                        XCTAssertEqual(try readValue.byteA(), value, column)
                        
                    default: XCTFail("Unexpected type: \(type(of: value))")
                    }
                } catch {
                    XCTFail(String(describing: error))
                }
            }
            
            // character varying
            check("cv", "")
            check("cv", "hello")
            check("cv", "你好世界")
            check("cv", "🐶🐮")
            
            // character
            check("c", "          ")
            check("c", "hello     ")
            check("c", "你好世界      ")
            check("c", "🐶🐮        ")
            
            // int
            check("i", 0)
            check("i", 314)
            check("i", -314)
            
            // smallint
            check("si", 0)
            check("si", 314)
            check("si", -314)
            
            // bigint
            check("bi", 0)
            check("bi", 314)
            check("bi", -314)
            
            // double precision
            check("dp", -314.0)
            check("dp", -1003.14159)
            check("dp", 6.02e+23)
            check("dp", 1.6021765e-19)
            check("dp", Double.infinity)
            check("dp", Double.signalingNaN)

            // real
            check("r", -314.0)
            check("r", -1003.14)
            check("r", 6.02e+23)
            check("r", 1.60218e-19)
            check("r", Double.infinity)
            check("r", Double.signalingNaN)

            // numeric
            check("n", Decimal(string: "1234.0"))
            check("n", Decimal(string: "+0001234.4321000"))
            check("n", Decimal(string: "-12345678987654321.98765432123456789"))
            check("n", Decimal.nan)
            check("n", Decimal.quietNaN)
            
            // boolean
            check("b", true)
            check("b", false)
            
            // timestamp with time zone
            check("tstz", PostgresTimestampWithTimeZone("2019-01-02 03:04:05.365-08"))
            check("tstz", PostgresTimestampWithTimeZone("2019-01-02 03:04:05.365+130"))

            // timestamp
            check("ts", PostgresTimestamp("2019-01-02 03:04:05.365"))
            
            // date
            check("d", PostgresDate("2019-01-02"))
            
            // time
            check("t", PostgresTime("03:04:05.365"))
            
            // time with time zone
            check("ttz", PostgresTimeWithTimeZone("03:04:05.365-08:00"))
            check("ttz", PostgresTimeWithTimeZone("03:04:05.365+1:30"))

            // bytea
            check("ba", PostgresByteA("\\xDEADBEEF"))
            
            var bs = [UInt8]()
            
            for _ in 0..<1_000_000 {
                bs.append(UInt8.random(in: 0...255))
            }
            
            let data = Data(bs)

            check("ba", PostgresByteA(data: data))
            
        } catch {
            XCTFail(String(describing: error))
        }
    }
}

// EOF
