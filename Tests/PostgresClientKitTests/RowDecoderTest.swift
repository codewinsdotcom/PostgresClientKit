//
//  RowDecoderTest.swift
//  PostgresClientKit
//
//  Copyright 2022 David Pitfield and the PostgresClientKit contributors
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

/// Tests RowDecoder.
class RowDecoderTest: PostgresClientKitTestCase {

    override func setUp() {
        do {
            try createWeatherTable()
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    struct WeatherStruct: Decodable, Equatable {
        let date: PostgresDate
        let city: String
        let temp_lo: Int
        let temp_hi: Int
        let prcp: Double?
    }
    
    class WeatherClass: Decodable, Equatable {
        
        init(date: PostgresDate, city: String, temp_lo: Int, temp_hi: Int, prcp: Double?) {
            self.date = date
            self.city = city
            self.temp_lo = temp_lo
            self.temp_hi = temp_hi
            self.prcp = prcp
        }

        let date: PostgresDate
        let city: String
        let temp_lo: Int
        let temp_hi: Int
        let prcp: Double?
        
        static func == (lhs: WeatherClass, rhs: WeatherClass) -> Bool {
            return lhs.date == rhs.date &&
            lhs.city == rhs.city &&
            lhs.temp_lo == rhs.temp_lo &&
            lhs.temp_hi == rhs.temp_hi &&
            lhs.prcp == rhs.prcp
        }
    }
    
    func testBasicOperation() {

        let weatherExpectedResults = [
            WeatherStruct(date: PostgresDate("1994-11-27")!, city: "San Francisco", temp_lo: 46, temp_hi: 50, prcp: 0.25),
            WeatherStruct(date: PostgresDate("1994-11-29")!, city: "Hayward", temp_lo: 37, temp_hi: 54, prcp: nil),
            WeatherStruct(date: PostgresDate("1994-11-29")!, city: "San Francisco", temp_lo: 43, temp_hi: 57, prcp: 0)
        ]
        
        struct StringAndOptionalString: Decodable, Equatable {
            let string: String
            let optionalString: String?
        }
        
        /// decodeByColumnName: basic scenario
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherStruct.self),
            weatherExpectedResults)

        /// decodeByColumnName: fails if retrieveColumnMetadata is false
        try XCTAssertThrowsError(
            decodeByColumnName(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherStruct.self,
                retrieveColumnMetadata: false))
        { error in
            guard case PostgresError.columnMetadataNotAvailable = error else {
                return XCTFail(String(describing: error))
            }
        }

        /// decodeByColumnName: column order doesn't matter
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT city, temp_lo, temp_hi, prcp, date FROM weather ORDER BY date, city;",
                type: WeatherStruct.self),
            weatherExpectedResults)

        /// decodeByColumnName: extra columns are ignored
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT 'hello' x1, date, city, 314 x2, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherStruct.self),
            weatherExpectedResults)

        /// decodeByColumnName: another basic scenario
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT 's1' string, 's2' optionalString;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: "s2")])
        
        /// decodeByColumnName: duplicate column names (last one wins)
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT 's1' string, 's2' optionalString, 's3' string;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s3", optionalString: "s2")])
        
        /// decodeByColumnName: column names are case-insensitive
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT 's1' \"STRING\", 's2' \"optionalSTRING\";",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: "s2")])

        /// decodeByColumnName: a missing column for an optional property is allowed
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT 's1' string;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: nil)])

        /// decodeByColumnName: fails if missing a column for a non-optional property
        try XCTAssertThrowsError(
            decodeByColumnName(
                sql: "SELECT 's2' optionalString;",
                type: StringAndOptionalString.self))
        { error in
            guard case DecodingError.keyNotFound = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        /// decodeByColumnName: fails if a non-optional property is NULL
        try XCTAssertThrowsError(
            decodeByColumnName(
                sql: "SELECT NULL string;",
                type: StringAndOptionalString.self))
        { error in
            guard case DecodingError.valueNotFound = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        /// decodeByColumnIndex: basic scenario
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherStruct.self),
            weatherExpectedResults)
        
        /// decodeByColumnIndex: column order does matter
        try XCTAssertThrowsError(
            decodeByColumnIndex(
                sql: "SELECT city, temp_lo, temp_hi, prcp, date FROM weather ORDER BY date, city;",
                type: WeatherStruct.self))
        { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail(String(describing: error))
            }
        }

        /// decodeByColumnIndex: extra columns are ignored (if at the end)
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp, 'hello' x1 FROM weather ORDER BY date, city;",
                type: WeatherStruct.self),
            weatherExpectedResults)
        
        /// decodeByColumnIndex: another basic scenario
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT 's1' string, 's2' optionalString;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: "s2")])
        
        /// decodeByColumnIndex: column names are ignored
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT 's1' optionalString, 's2' string;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: "s2")])
        
        /// decodeByColumnIndex: column names are ignored
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT 's1' foo, 's2' foo;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: "s2")])
        
        /// decodeByColumnIndex: a missing column for an optional property is allowed
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT 's1' string;",
                type: StringAndOptionalString.self),
            [StringAndOptionalString(string: "s1", optionalString: nil)])
        
        /// decodeByColumnIndex: fails if missing a column for a non-optional property
        try XCTAssertThrowsError(
            decodeByColumnIndex(
                sql: "SELECT;",
                type: StringAndOptionalString.self))
        { error in
            guard case DecodingError.keyNotFound = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        /// decodeByColumnIndex: fails if a non-optional property is NULL
        try XCTAssertThrowsError(
            decodeByColumnIndex(
                sql: "SELECT NULL string;",
                type: StringAndOptionalString.self))
        { error in
            guard case DecodingError.valueNotFound = error else {
                return XCTFail(String(describing: error))
            }
        }
    }
    
    func testDecodableClass() {
        
        let weatherExpectedResults = [
            WeatherClass(date: PostgresDate("1994-11-27")!, city: "San Francisco", temp_lo: 46, temp_hi: 50, prcp: 0.25),
            WeatherClass(date: PostgresDate("1994-11-29")!, city: "Hayward", temp_lo: 37, temp_hi: 54, prcp: nil),
            WeatherClass(date: PostgresDate("1994-11-29")!, city: "San Francisco", temp_lo: 43, temp_hi: 57, prcp: 0)
        ]
        
        /// decodeByColumnName: basic scenario
        try XCTAssertEqual(
            decodeByColumnName(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherClass.self),
            weatherExpectedResults)

        /// decodeByColumnIndex: basic scenario
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather ORDER BY date, city;",
                type: WeatherClass.self),
            weatherExpectedResults)
    }
    
    func testStandardLibraryTypes() {
        
        struct StandardLibraryTypes: Decodable, Equatable {
            let bool: Bool
            let string: String
            let double: Double
            let float: Float
            let int: Int
            let int8: Int8
            let int16: Int16
            let int32: Int32
            let int64: Int64
            let uint: UInt
            let uint8: UInt8
            let uint16: UInt16
            let uint32: UInt32
            let uint64: UInt64
        }
        
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql:
                    """
                    SELECT
                    true, 'hello', 3.14, -3.14,
                    -9223372036854775808, -128, -32768, -2147483648, -9223372036854775808,
                    18446744073709551615, 255, 65535, 4294967295, 18446744073709551615;
                    """,
                type: StandardLibraryTypes.self),
            [StandardLibraryTypes(
                bool: true, string: "hello", double: 3.14, float: -3.14,
                int: Int.min, int8: Int8.min, int16: Int16.min, int32: Int32.min, int64: Int64.min,
                uint: UInt.max, uint8: UInt8.max, uint16: UInt16.max, uint32: UInt32.max, uint64: UInt64.max)])
             
        struct Int8AndDouble: Decodable, Equatable {
            let int8: Int8?
            let double: Double?
        }

        try XCTAssertEqual(
            decodeByColumnIndex(
                sql: "SELECT '123', '3.14';",
                type: Int8AndDouble.self),
            [Int8AndDouble(int8: 123, double: 3.14)])

        try XCTAssertThrowsError(
            decodeByColumnIndex(
                sql: "SELECT 123.4, NULL;",
                type: Int8AndDouble.self))
        { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail(String(describing: error))
            }
        }
        
        try XCTAssertThrowsError(
            decodeByColumnIndex(
                sql: "SELECT NULL, '3point14';",
                type: Int8AndDouble.self))
        { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail(String(describing: error))
            }
        }
    }
    
    func testPostgresClientKitTypes() {
        
        struct PostgresClientKitTypes: Decodable, Equatable {
            let postgresByteA: PostgresByteA
            let postgresTimestampWithTimeZone: PostgresTimestampWithTimeZone
            let postgresTimestamp: PostgresTimestamp
            let postgresDate: PostgresDate
            let postgresTime: PostgresTime
            let postgresTimeWithTimeZone: PostgresTimeWithTimeZone
        }
        
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql:
                    """
                    SELECT
                    CAST('\\xdeadbeef' as BYTEA),
                    CAST('2019-03-14 16:25:19.365+00:00' as TIMESTAMP WITH TIME ZONE),
                    CAST('2019-03-14 16:25:19.365' as TIMESTAMP),
                    CAST('2019-03-14' as DATE),
                    CAST('16:25:19.365' as TIME),
                    CAST('16:25:19.365+00:00' as TIME WITH TIME ZONE);
                    """,
                type: PostgresClientKitTypes.self),
            [PostgresClientKitTypes(
                postgresByteA: PostgresByteA("\\xDEADBEEF")!,
                postgresTimestampWithTimeZone: PostgresTimestampWithTimeZone("2019-03-14 16:25:19.365+00:00")!,
                postgresTimestamp: PostgresTimestamp("2019-03-14 16:25:19.365")!,
                postgresDate: PostgresDate("2019-03-14")!,
                postgresTime: PostgresTime("16:25:19.365")!,
                postgresTimeWithTimeZone: PostgresTimeWithTimeZone("16:25:19.365+00:00")!)])
    }
    
    func testFoundationDate() {
                
        struct FoundationDate: Decodable, Equatable {
            let dateFromTimestampWithTimeZone: Date
            let dateFromTimestamp: Date
            let dateFromDate: Date
            let dateFromTime: Date
            let dateFromTimeWithTimeZone: Date
        }
        
        let utcTimeZone = TimeZone(secondsFromGMT: 0)!

        try XCTAssertEqual(
            decodeByColumnIndex(
                sql:
                    """
                    SELECT
                    '2019-03-14 16:25:19.365+00:00',
                    '2019-03-14 16:25:19.365',
                    '2019-03-14',
                    '16:25:19.365',
                    '16:25:19.365+00:00';
                    """,
                type: FoundationDate.self),
            [FoundationDate(
                dateFromTimestampWithTimeZone: PostgresTimestampWithTimeZone("2019-03-14 16:25:19.365+00:00")!.date,
                dateFromTimestamp: PostgresTimestamp("2019-03-14 16:25:19.365")!.date(in: utcTimeZone),
                dateFromDate: PostgresDate("2019-03-14")!.date(in: utcTimeZone),
                dateFromTime: PostgresTime("16:25:19.365")!.date(in: utcTimeZone),
                dateFromTimeWithTimeZone: PostgresTimeWithTimeZone("16:25:19.365+00:00")!.date)])

        let pstTimeZone = TimeZone(secondsFromGMT: -8 * 60 * 60)!
        
        try XCTAssertEqual(
            decodeByColumnIndex(
                sql:
                    """
                    SELECT
                    '2019-03-14 16:25:19.365-08:00',
                    '2019-03-14 16:25:19.365',
                    '2019-03-14',
                    '16:25:19.365',
                    '16:25:19.365-08:00';
                    """,
                type: FoundationDate.self,
                defaultTimeZone: pstTimeZone),
            [FoundationDate(
                dateFromTimestampWithTimeZone: PostgresTimestampWithTimeZone("2019-03-14 16:25:19.365-08:00")!.date,
                dateFromTimestamp: PostgresTimestamp("2019-03-14 16:25:19.365")!.date(in: pstTimeZone),
                dateFromDate: PostgresDate("2019-03-14")!.date(in: pstTimeZone),
                dateFromTime: PostgresTime("16:25:19.365")!.date(in: pstTimeZone),
                dateFromTimeWithTimeZone: PostgresTimeWithTimeZone("16:25:19.365-08:00")!.date)])
    }
    
    func testPerformance() {
        do {
            // INSERT 1000 days of random weather records for San Jose.
            let connection = try Connection(configuration: terryConnectionConfiguration())
            try connection.beginTransaction()
            let text = "INSERT INTO weather (date, city, temp_lo, temp_hi, prcp) VALUES ($1, $2, $3, $4, $5)"
            let statement = try connection.prepareStatement(text: text)
            var weatherHistory = [WeatherStruct]()
            
            for i in 0..<1_000 {
                
                let tempLo = Int.random(in: 20...70)
                let tempHi = Int.random(in: tempLo...100)
                
                let prcp: Double? = {
                    let r = Double.random(in: 0..<1)
                    if r < 0.1 { return nil }
                    if r < 0.8 { return 0.0 }
                    return Double(Int.random(in: 1...20)) / 10.0
                }()
                
                let date: PostgresDate = {
                    let pgd = PostgresDate(year: 2000, month: 1, day: 1)!
                    var d = pgd.date(in: utcTimeZone)
                    d = enUsPosixUtcCalendar.date(byAdding: .day, value: i, to: d)!
                    return d.postgresDate(in: utcTimeZone)
                }()
                
                let weather = WeatherStruct(
                    date: date, city: "San Jose", temp_lo: tempLo, temp_hi: tempHi, prcp: prcp)
                
                weatherHistory.append(weather)
                
                let cursor = try statement.execute(parameterValues:
                    [ weather.date, weather.city, weather.temp_lo, weather.temp_hi, weather.prcp ])
                
                XCTAssertEqual(cursor.rowCount, 1)
            }
            
            try connection.commitTransaction()

            // SELECT the weather records and decode by name
            var selectedWeatherHistory = [WeatherStruct]()
            try time("SELECT \(weatherHistory.count) rows and decode by name") {
                selectedWeatherHistory = try decodeByColumnName(
                    sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather WHERE city = 'San Jose' ORDER BY date;",
                    type: WeatherStruct.self)
            }
            XCTAssertEqual(selectedWeatherHistory, weatherHistory)

            // SELECT the weather records and decode by index
            try time("SELECT \(weatherHistory.count) rows and decode by index") {
                selectedWeatherHistory = try decodeByColumnIndex(
                    sql: "SELECT date, city, temp_lo, temp_hi, prcp FROM weather WHERE city = 'San Jose' ORDER BY date;",
                    type: WeatherStruct.self)
            }
            XCTAssertEqual(selectedWeatherHistory, weatherHistory)
        } catch {
            XCTFail(String(describing: error))
        }
    }
    
    
    //
    // MARK: Helper functions
    //
    
    func decodeByColumnName<T>(sql: String,
                               type: T.Type,
                               retrieveColumnMetadata: Bool = true,
                               defaultTimeZone: TimeZone? = nil) throws -> [T] where T: Decodable {
        let connection = try Connection(configuration: terryConnectionConfiguration())
        let statement = try connection.prepareStatement(text: sql)
        let cursor = try statement.execute(retrieveColumnMetadata: retrieveColumnMetadata)
        var results = [T]()
        
        for row in cursor {
            results  += [ try row.get().decodeByColumnName(T.self, defaultTimeZone: defaultTimeZone) ]
        }
        
        return results
    }
    
    func decodeByColumnIndex<T>(sql: String,
                                type: T.Type,
                                defaultTimeZone: TimeZone? = nil) throws -> [T] where T: Decodable {
        
        let connection = try Connection(configuration: terryConnectionConfiguration())
        let statement = try connection.prepareStatement(text: sql)
        let cursor = try statement.execute(retrieveColumnMetadata: false)
        var results = [T]()

        for row in cursor {
            results  += [ try row.get().decodeByColumnIndex(T.self, defaultTimeZone: defaultTimeZone) ]
        }
        
        return results
    }
    
    func time(_ name: String, operation: () throws -> Void) throws {
        let start = Date()
        try operation()
        let elapsed = Date().timeIntervalSince(start) * 1000
        Postgres.logger.info("\(name): elapsed time \(elapsed) ms")
    }
}

// EOF
