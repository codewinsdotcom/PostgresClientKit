//
//  LoggingTest.swift
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

/// Tests logging.
class LoggingTest: PostgresClientKitTestCase {
    
    func test() {
        
        let logger = Logger()
        XCTAssertEqual(logger.level, .info)
        XCTAssert(logger.handler is ConsoleLogHandler)
        
        XCTAssertTrue(logger.isLoggable(level: .severe))
        XCTAssertTrue(logger.isLoggable(level: .warning))
        XCTAssertTrue(logger.isLoggable(level: .info))
        XCTAssertFalse(logger.isLoggable(level: .fine))
        XCTAssertFalse(logger.isLoggable(level: .finer))
        XCTAssertFalse(logger.isLoggable(level: .finest))
        
        logger.level = .off
        XCTAssertEqual(logger.level, .off)
        XCTAssertFalse(logger.isLoggable(level: .severe))
        XCTAssertFalse(logger.isLoggable(level: .warning))
        XCTAssertFalse(logger.isLoggable(level: .info))
        XCTAssertFalse(logger.isLoggable(level: .fine))
        XCTAssertFalse(logger.isLoggable(level: .finer))
        XCTAssertFalse(logger.isLoggable(level: .finest))
        
        logger.level = .all
        XCTAssertEqual(logger.level, .all)
        XCTAssertTrue(logger.isLoggable(level: .severe))
        XCTAssertTrue(logger.isLoggable(level: .warning))
        XCTAssertTrue(logger.isLoggable(level: .info))
        XCTAssertTrue(logger.isLoggable(level: .fine))
        XCTAssertTrue(logger.isLoggable(level: .finer))
        XCTAssertTrue(logger.isLoggable(level: .finest))
        
        logger.level = .info
        
        let testLogHandler = TestLogHandler()
        logger.handler = testLogHandler
        XCTAssertTrue(logger.handler is TestLogHandler)
        
        let epoch = Date(timeIntervalSince1970: 0)
        
        let logRecord = LogRecord(level: .info,
                                  message: "Hello",
                                  context: "Session-123",
                                  timestamp: epoch,
                                  file: "Foo.swift",
                                  function: "bar()",
                                  line: 42)
        
        XCTAssertEqual(logRecord.level, .info)
        XCTAssertEqual(String(describing: logRecord.message), "Hello")
        XCTAssertEqual(String(describing: logRecord.context ?? ""), "Session-123")
        XCTAssertEqual(logRecord.timestamp, epoch)
        XCTAssertEqual(logRecord.file, "Foo.swift")
        XCTAssertEqual(logRecord.function, "bar()")
        XCTAssertEqual(logRecord.line, 42)
        
        logger.log(logRecord)
        
        logger.log(level: .info, message: "Bonjour", context: "Session-123")
        
        logger.severe("This is severe", context: "Session-123")
        logger.warning("This is warning", context: "Session-123")
        logger.info("This is info", context: "Session-123")
        logger.fine("This is fine")
        logger.finer("This is finer")
        logger.finest("This is finest")
        
        XCTAssertEqual(testLogHandler.recordsLogged, 5)
    }
    
    class TestLogHandler: LogHandler {
        
        let consoleLogHandler = ConsoleLogHandler()
        var recordsLogged = 0
        
        func log(_ logRecord: LogRecord) {
            
            consoleLogHandler.log(logRecord)
            
            if recordsLogged == 0 {
                XCTAssertEqual(logRecord.level, .info)
                XCTAssertEqual(String(describing: logRecord.message), "Hello")
                XCTAssertEqual(logRecord.timestamp, Date(timeIntervalSince1970: 0))
                XCTAssertEqual(logRecord.file, "Foo.swift")
                XCTAssertEqual(logRecord.function, "bar()")
                XCTAssertEqual(logRecord.line, 42)
            } else {
                XCTAssertEqual(logRecord.file, #file)
                XCTAssertEqual(logRecord.function, "test()")
            }
            
            XCTAssertEqual(String(describing: logRecord.context ?? ""), "Session-123")
            
            recordsLogged = recordsLogged + 1
        }
    }
}

// EOF
