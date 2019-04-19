//
//  PostgresValueTest.swift
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

/// Tests PostgresValue.
class PostgresValueTest: PostgresClientKitTestCase {
    
    func test() {
        
        let frFrLocale = Locale(identifier: "fr_FR")
        
        func check(
            postgresValueConvertible: PostgresValueConvertible,
            expectedRawValue: String,
            expectedString: String?,
            expectedInt: Int?,
            expectedDouble: Double?,
            expectedDecimal: Decimal?,
            expectedBool: Bool?,
            expectedTimestampWithTimeZone: PostgresTimestampWithTimeZone?,
            expectedTimestamp: PostgresTimestamp?,
            expectedDate: PostgresDate?,
            expectedTime: PostgresTime?,
            expectedTimeWithTimeZone: PostgresTimeWithTimeZone?,
            expectedByteA: PostgresByteA?,
            file: StaticString = #file,
            line: UInt = #line) {
            
            let postgresValue = postgresValueConvertible.postgresValue
            
            var message = "rawValue"
            XCTAssertEqual(postgresValue.rawValue, expectedRawValue, message, file: file, line: line)
            
            message = "string"
            if let expectedString = expectedString {
                XCTAssertEqual(try postgresValue.string(), expectedString, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalString(), .some(expectedString), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.string(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalString(), message, file: file, line: line)
            }
            
            message = "int"
            if let expectedInt = expectedInt {
                XCTAssertEqual(try postgresValue.int(), expectedInt, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalInt(), .some(expectedInt), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.int(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalInt(), message, file: file, line: line)
            }
            
            message = "double"
            if expectedDouble?.isNaN ?? false {
                XCTAssertTrue(try postgresValue.double().isNaN, message, file: file, line: line)
                XCTAssertTrue(try postgresValue.optionalDouble()!.isNaN, message, file: file, line: line)
            } else if let expectedDouble = expectedDouble {
                XCTAssertEqual(try postgresValue.double(), expectedDouble, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalDouble(), .some(expectedDouble), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.double(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalDouble(), message, file: file, line: line)
            }
            
            message = "decimal"
            if let expectedDecimal = expectedDecimal {
                XCTAssertEqual(try postgresValue.decimal(), expectedDecimal, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalDecimal(), .some(expectedDecimal), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.decimal(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalDecimal(), message, file: file, line: line)
            }
            
            message = "bool"
            if let expectedBool = expectedBool {
                XCTAssertEqual(try postgresValue.bool(), expectedBool, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalBool(), .some(expectedBool), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.bool(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalBool(), message, file: file, line: line)
            }
            
            message = "timestampWithTimeZone"
            if let expectedTimestampWithTimeZone = expectedTimestampWithTimeZone {
                XCTAssertEqual(try postgresValue.timestampWithTimeZone(), expectedTimestampWithTimeZone, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalTimestampWithTimeZone(), .some(expectedTimestampWithTimeZone), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.timestampWithTimeZone(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalTimestampWithTimeZone(), message, file: file, line: line)
            }
            
            message = "timestamp"
            if let expectedTimestamp = expectedTimestamp {
                XCTAssertEqual(try postgresValue.timestamp(), expectedTimestamp, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalTimestamp(), .some(expectedTimestamp), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.timestamp(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalTimestamp(), message, file: file, line: line)
            }
            
            message = "date"
            if let expectedDate = expectedDate {
                XCTAssertEqual(try postgresValue.date(), expectedDate, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalDate(), .some(expectedDate), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.date(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalDate(), message, file: file, line: line)
            }
            
            message = "time"
            if let expectedTime = expectedTime {
                XCTAssertEqual(try postgresValue.time(), expectedTime, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalTime(), .some(expectedTime), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.time(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalTime(), message, file: file, line: line)
            }
            
            message = "timeWithTimeZone"
            if let expectedTimeWithTimeZone = expectedTimeWithTimeZone {
                XCTAssertEqual(try postgresValue.timeWithTimeZone(), expectedTimeWithTimeZone, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalTimeWithTimeZone(), .some(expectedTimeWithTimeZone), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.timeWithTimeZone(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalTimeWithTimeZone(), message, file: file, line: line)
            }
            
            message = "byteA"
            if let expectedByteA = expectedByteA {
                XCTAssertEqual(try postgresValue.byteA(), expectedByteA, message, file: file, line: line)
                XCTAssertEqual(try postgresValue.optionalByteA(), .some(expectedByteA), message, file: file, line: line)
            } else {
                XCTAssertThrowsError(try postgresValue.byteA(), message, file: file, line: line)
                XCTAssertThrowsError(try postgresValue.optionalByteA(), message, file: file, line: line)
            }
        }
        
        func shouldFail<T>() -> T? {
            return nil
        }
        
        
        //
        // Test init(_:)
        //
        
        let value = PostgresValue("hello")
        XCTAssertEqual(value.rawValue, "hello")
        XCTAssertFalse(value.isNull)
        XCTAssertEqual(value.postgresValue, value)
        XCTAssertEqual(value, value)
        XCTAssertEqual(value.description, "hello")

        let value2 = PostgresValue(nil)
        XCTAssertEqual(value2.rawValue, nil)
        XCTAssertTrue(value2.isNull)
        XCTAssertEqual(value2.postgresValue, value2)
        XCTAssertEqual(value2, value2)
        XCTAssertNotEqual(value2, value)
        XCTAssertEqual(value2.description, "nil")
        
        
        //
        // Test conversion from String.
        //
        
        check(postgresValueConvertible: "hello",
              expectedRawValue: "hello",
              expectedString: "hello",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "0",
              expectedRawValue: "0",
              expectedString: "0",
              expectedInt: 0,
              expectedDouble: 0.0,
              expectedDecimal: Decimal(0),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "314",
              expectedRawValue: "314",
              expectedString: "314",
              expectedInt: 314,
              expectedDouble: 314.0,
              expectedDecimal: Decimal(314),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "+03140",
              expectedRawValue: "+03140",
              expectedString: "+03140",
              expectedInt: 3140,
              expectedDouble: 3140.0,
              expectedDecimal: Decimal(3140),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "-314",
              expectedRawValue: "-314",
              expectedString: "-314",
              expectedInt: -314,
              expectedDouble: -314.0,
              expectedDecimal: Decimal(-314),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "-314.0",
              expectedRawValue: "-314.0",
              expectedString: "-314.0",
              expectedInt: shouldFail(),
              expectedDouble: -314.0,
              expectedDecimal: Decimal(-314.0),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "-1003.141590",
              expectedRawValue: "-1003.141590",
              expectedString: "-1003.141590",
              expectedInt: shouldFail(),
              expectedDouble: -1003.14159,
              expectedDecimal: Decimal(-1003.14159),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "6.02E23",
              expectedRawValue: "6.02E23",
              expectedString: "6.02E23",
              expectedInt: shouldFail(),
              expectedDouble: 6.02e+23,
              expectedDecimal: Decimal(6.02e+23),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())

        check(postgresValueConvertible: "1.6021765000e-19",
              expectedRawValue: "1.6021765000e-19",
              expectedString: "1.6021765000e-19",
              expectedInt: shouldFail(),
              expectedDouble: 1.6021765e-19,
              expectedDecimal: Decimal(1.6021765e-19),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "inf",
              expectedRawValue: "inf",
              expectedString: "inf",
              expectedInt: shouldFail(),
              expectedDouble: Double.infinity,
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "infinity",
              expectedRawValue: "infinity",
              expectedString: "infinity",
              expectedInt: shouldFail(),
              expectedDouble: Double.infinity,
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "nan",
              expectedRawValue: "nan",
              expectedString: "nan",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "NaN",
              expectedRawValue: "NaN",
              expectedString: "NaN",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "-12345678987654321.98765432123456789",
              expectedRawValue: "-12345678987654321.98765432123456789",
              expectedString: "-12345678987654321.98765432123456789",
              expectedInt: shouldFail(),
              expectedDouble: -12345678987654321.98765432123456789, // literal will be rounded to nearest Double
              expectedDecimal: Decimal(string: "-12345678987654321.98765432123456789", locale: enUsPosixLocale),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())

        check(postgresValueConvertible: "t",
              expectedRawValue: "t",
              expectedString: "t",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: true,
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "f",
              expectedRawValue: "f",
              expectedString: "f",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: false,
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())

        check(postgresValueConvertible: "2019-01-02 03:04:05.365-08",
              expectedRawValue: "2019-01-02 03:04:05.365-08",
              expectedString: "2019-01-02 03:04:05.365-08",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: PostgresTimestampWithTimeZone("2019-01-02 11:04:05.365+00:00"),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "2019-01-02 03:04:05.365",
              expectedRawValue: "2019-01-02 03:04:05.365",
              expectedString: "2019-01-02 03:04:05.365",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: PostgresTimestamp("2019-01-02 03:04:05.365"),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "2019-01-02",
              expectedRawValue: "2019-01-02",
              expectedString: "2019-01-02",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: PostgresDate("2019-01-02"),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "03:04:05.365",
              expectedRawValue: "03:04:05.365",
              expectedString: "03:04:05.365",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(3), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: PostgresTime("03:04:05.365"),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "03:04:05.365-08",
              expectedRawValue: "03:04:05.365-08",
              expectedString: "03:04:05.365-08",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(3), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: PostgresTimeWithTimeZone("03:04:05.365-08:00"),
              expectedByteA: shouldFail())

        check(postgresValueConvertible: "\\xDEADBEEF",
              expectedRawValue: "\\xDEADBEEF",
              expectedString: "\\xDEADBEEF",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: PostgresByteA("\\xdeadbeef"))


        //
        // Test conversion from Int.
        //
        
        check(postgresValueConvertible: 0,
              expectedRawValue: "0",
              expectedString: "0",
              expectedInt: 0,
              expectedDouble: 0.0,
              expectedDecimal: Decimal(0),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: 314,
              expectedRawValue: "314",
              expectedString: "314",
              expectedInt: 314,
              expectedDouble: 314.0,
              expectedDecimal: Decimal(314),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: -314,
              expectedRawValue: "-314",
              expectedString: "-314",
              expectedInt: -314,
              expectedDouble: -314.0,
              expectedDecimal: Decimal(-314),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from Double.
        //
        
        check(postgresValueConvertible: -314.0,
              expectedRawValue: "-314.0",
              expectedString: "-314.0",
              expectedInt: shouldFail(),
              expectedDouble: -314.0,
              expectedDecimal: Decimal(-314.0),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: -1003.14159,
              expectedRawValue: "-1003.14159",
              expectedString: "-1003.14159",
              expectedInt: shouldFail(),
              expectedDouble: -1003.14159,
              expectedDecimal: Decimal(-1003.14159),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: 6.02E23,
              expectedRawValue: "6.02e+23",
              expectedString: "6.02e+23",
              expectedInt: shouldFail(),
              expectedDouble: 6.02e+23,
              expectedDecimal: Decimal(6.02e+23),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: "1.6021765e-19",
              expectedRawValue: "1.6021765e-19",
              expectedString: "1.6021765e-19",
              expectedInt: shouldFail(),
              expectedDouble: 1.6021765e-19,
              expectedDecimal: Decimal(1.6021765e-19),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Double.infinity,
              expectedRawValue: "inf",
              expectedString: "inf",
              expectedInt: shouldFail(),
              expectedDouble: Double.infinity,
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Double.nan,
              expectedRawValue: "nan",
              expectedString: "nan",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Double.signalingNaN,
              expectedRawValue: "nan",
              expectedString: "nan",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        

        //
        // Test conversion from Decimal.
        //
        
        check(postgresValueConvertible: Decimal(string: "1234.0", locale: enUsPosixLocale),
              expectedRawValue: "1234",
              expectedString: "1234",
              expectedInt: 1234,
              expectedDouble: 1234.0,
              expectedDecimal: Decimal(string: "1234", locale: enUsPosixLocale),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Decimal(string: "+0001234.4321000", locale: enUsPosixLocale),
              expectedRawValue: "1234.4321",
              expectedString: "1234.4321",
              expectedInt: shouldFail(),
              expectedDouble: 1234.4321,
              expectedDecimal: Decimal(string: "1234.4321", locale: enUsPosixLocale),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Decimal(string: "-12345678987654321.98765432123456789", locale: enUsPosixLocale),
              expectedRawValue: "-12345678987654321.98765432123456789",
              expectedString: "-12345678987654321.98765432123456789",
              expectedInt: shouldFail(),
              expectedDouble: -12345678987654321.98765432123456789, // literal will be rounded to nearest Double
              expectedDecimal: Decimal(string: "-12345678987654321.98765432123456789", locale: enUsPosixLocale),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())

        check(postgresValueConvertible: Decimal(string: "-12345678987654321,98765432123456789", locale: frFrLocale),
              expectedRawValue: "-12345678987654321.98765432123456789",
              expectedString: "-12345678987654321.98765432123456789",
              expectedInt: shouldFail(),
              expectedDouble: -12345678987654321.98765432123456789, // literal will be rounded to nearest Double
              expectedDecimal: Decimal(string: "-12345678987654321.98765432123456789", locale: enUsPosixLocale),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Decimal.nan,
              expectedRawValue: "NaN",
              expectedString: "NaN",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: Decimal.quietNaN,
              expectedRawValue: "NaN",
              expectedString: "NaN",
              expectedInt: shouldFail(),
              expectedDouble: Double.nan,
              expectedDecimal: Decimal.nan,
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from Bool.
        //
        
        check(postgresValueConvertible: true,
              expectedRawValue: "t",
              expectedString: "t",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: true,
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        check(postgresValueConvertible: false,
              expectedRawValue: "f",
              expectedString: "f",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: false,
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresTimestampWithTimeZone.
        //
        
        check(postgresValueConvertible: PostgresTimestampWithTimeZone("2019-01-02 03:04:05.365-08"),
              expectedRawValue: "2019-01-02 11:04:05.365+00:00",
              expectedString: "2019-01-02 11:04:05.365+00:00",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: PostgresTimestampWithTimeZone("2019-01-02 11:04:05.365+00:00"),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresTimestamp.
        //
        
        check(postgresValueConvertible: PostgresTimestamp("2019-01-02 03:04:05.365"),
              expectedRawValue: "2019-01-02 03:04:05.365",
              expectedString: "2019-01-02 03:04:05.365",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: PostgresTimestamp("2019-01-02 03:04:05.365"),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresDate.
        //
        
        check(postgresValueConvertible: PostgresDate("2019-01-02"),
              expectedRawValue: "2019-01-02",
              expectedString: "2019-01-02",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(2019), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: PostgresDate("2019-01-02"),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresTime.
        //
        
        check(postgresValueConvertible: PostgresTime("03:04:05.365"),
              expectedRawValue: "03:04:05.365",
              expectedString: "03:04:05.365",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(3), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: PostgresTime("03:04:05.365"),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresTimeWithTimeZone.
        //
        
        check(postgresValueConvertible: PostgresTimeWithTimeZone("03:04:05.365-08"),
              expectedRawValue: "03:04:05.365-08:00",
              expectedString: "03:04:05.365-08:00",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: Decimal(3), // Decimal(string:locale:) behavior is dubious
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: PostgresTimeWithTimeZone("03:04:05.365-08:00"),
              expectedByteA: shouldFail())
        
        
        //
        // Test conversion from PostgresByteA.
        //
        
        check(postgresValueConvertible: PostgresByteA("\\xDEADBEEF"),
              expectedRawValue: "\\xdeadbeef",
              expectedString: "\\xdeadbeef",
              expectedInt: shouldFail(),
              expectedDouble: shouldFail(),
              expectedDecimal: shouldFail(),
              expectedBool: shouldFail(),
              expectedTimestampWithTimeZone: shouldFail(),
              expectedTimestamp: shouldFail(),
              expectedDate: shouldFail(),
              expectedTime: shouldFail(),
              expectedTimeWithTimeZone: shouldFail(),
              expectedByteA: PostgresByteA("\\xdeadbeef"))

        
        //
        // Test nil values.
        //
        
        var optionalString: String? = nil
        XCTAssertEqual(optionalString.postgresValue.rawValue, nil)
        XCTAssertEqual(optionalString.postgresValue, PostgresValue(nil))
        
        optionalString = "hello"
        XCTAssertEqual(optionalString.postgresValue.rawValue, "hello")
        XCTAssertEqual(optionalString.postgresValue, PostgresValue("hello"))

        let postgresValue = PostgresValue(nil)
        
        XCTAssertThrowsError(try postgresValue.string())
        XCTAssertEqual(try postgresValue.optionalString(), nil)

        XCTAssertThrowsError(try postgresValue.int())
        XCTAssertEqual(try postgresValue.optionalInt(), nil)
        
        XCTAssertThrowsError(try postgresValue.double())
        XCTAssertEqual(try postgresValue.optionalDouble(), nil)
        
        XCTAssertThrowsError(try postgresValue.decimal())
        XCTAssertEqual(try postgresValue.optionalDecimal(), nil)
        
        XCTAssertThrowsError(try postgresValue.bool())
        XCTAssertEqual(try postgresValue.optionalBool(), nil)
        
        XCTAssertThrowsError(try postgresValue.timestampWithTimeZone())
        XCTAssertEqual(try postgresValue.optionalTimestampWithTimeZone(), nil)
        
        XCTAssertThrowsError(try postgresValue.timestamp())
        XCTAssertEqual(try postgresValue.optionalTimestamp(), nil)
        
        XCTAssertThrowsError(try postgresValue.date())
        XCTAssertEqual(try postgresValue.optionalDate(), nil)
        
        XCTAssertThrowsError(try postgresValue.time())
        XCTAssertEqual(try postgresValue.optionalTime(), nil)
        
        XCTAssertThrowsError(try postgresValue.timeWithTimeZone())
        XCTAssertEqual(try postgresValue.optionalTimeWithTimeZone(), nil)
        
        XCTAssertThrowsError(try postgresValue.byteA())
        XCTAssertEqual(try postgresValue.optionalByteA(), nil)
    }
}

// EOF
