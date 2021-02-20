//
//  LogHandler.swift
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

/// An endpoint for log records.
///
/// If a `Logger` determines a `LogRecord` should be logged, that log record is dispatched to the
/// logger's current log handler.
///
/// A log handler might print the log record on the console, write it to a log file, forward it
/// to an external logging system, or otherwise process the log record.
///
/// - SeeAlso: `ConsoleLogHandler`
public protocol LogHandler {
    
    /// Called by a `Logger` to request this log handler process the specified log record.
    ///
    /// Implementations of this method must be threadsafe.
    ///
    /// - Parameter record: the log record
    func log(_ record: LogRecord)
}

/// A log handler that prints log records to standard output.
public class ConsoleLogHandler: LogHandler {
    
    /// Creates a `ConsoleLogHandler`.
    public init() { }
    
    /// A queue used to make this class threadsafe.
    private let queue = DispatchQueue(label: "Postgres.ConsoleLogHandler")
    
    /// Prints a log record to standard output.
    ///
    /// - Parameter record: the log record
    public func log(_ record: LogRecord) {
        
        // It is tempting to process the log record asynchronously.  But, since debugging is one
        // of the primary use cases for logging, it's useful to preserve the order of log records
        // relative to other cues (such as XCTest messages printed to stderr).  So we process the
        // log record synchronously with the invoking thread.
        queue.sync {
            let prefix = [
                ConsoleLogHandler.timestampFormatter.string(from: record.timestamp),
                String(describing: record.context ?? ""),
                String(describing: record.level) ]
                .filter { $0.count > 0 }
                .joined(separator: " ")
            
            print("[\(prefix)] \(record.message)")
        }
    }
    
    /// Formats timestamps in ISO8601 format.
    private static let timestampFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Postgres.enUsPosixLocale
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        df.timeZone = ISO8601.utcTimeZone
        return df
    }()
}

// EOF
