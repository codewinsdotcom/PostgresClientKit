//
//  Logger.swift
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

/// Logs events of interest.
///
/// A `LogRecord` describes a loggable event.  Each record has a level which reflects the importance
/// of the event.  If the log level of a record is at least as high as the `level` of the logger,
/// the logger dispatches the record to the logger's current `handler`.
///
/// Example:
///
///     let logger = Logger()
///     logger.level = .warning
///     logger.handler = ConsoleLogHandler()
///
///     let record = LogRecord(level: .warning,
///                            message: "Watch out!",
///                            context: "Session-14",
///                            timestamp: Date(),
///                            file: #file,
///                            function: #function,
///                            line: #line)
///
///     logger.log(record) // the record is logged (because LogLevel.warning >= logger.level)
///
///     // Convenience methods make logging more concise.
///     logger.warning("Watch out!", context: "Session-14")
///
///     // Examples of other log levels:
///     logger.severe("This is also logged") // because LogLevel.severe >= logger.level
///     logger.info("This is not logged")    // because LogLevel.info < logger.level
///
/// `Logger` is threadsafe.
///
/// - SeeAlso: `Postgres.logger`
public class Logger {
    
    /// Creates a `Logger`.
    public init() { }
    
    /// Used to make this logger instance threadsafe.
    private let semaphore = DispatchSemaphore(value: 1)
    
    /// The log level for this logger.  Defaults to `LogLevel.info`.
    public var level: LogLevel {
        get {
            semaphore.wait()
            defer { semaphore.signal() }
            return _level
        }
        set {
            semaphore.wait()
            defer { semaphore.signal() }
            _level = newValue
        }
    }
    private var _level = LogLevel.info
    
    /// The log handler for this logger.  Defaults to a `ConsoleLogHandler`.
    public var handler: LogHandler {
        get {
            semaphore.wait()
            defer { semaphore.signal() }
            return _handler
        }
        set {
            semaphore.wait()
            defer { semaphore.signal() }
            _handler = newValue
        }
    }
    private var _handler: LogHandler = ConsoleLogHandler()

    /// Gets whether a `LogRecord` with the specified log level would be logged.
    ///
    /// - Parameter level: the log level
    /// - Returns: whether logged
    public func isLoggable(level: LogLevel) -> Bool {
        return level >= self.level
    }
    
    /// Processes the specified log record.
    ///
    /// - Parameter record: the log record
    public func log(_ record: LogRecord) {
        if isLoggable(level: record.level) {
            handler.log(record)
        }
    }
    
    /// Convenience method to log an event.
    ///
    /// - Parameters:
    ///   - level: the log level that reflects the importance of the event
    ///   - message: a message describing the event
    ///   - context: the context of the event, such as a session or connection identifier
    ///   - file: the name of the file that logged the event
    ///   - function: the name of the function that logged the event
    ///   - line: the line number that logged the event
    public func log(level: LogLevel,
                    message: CustomStringConvertible,
                    context: CustomStringConvertible? = nil,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        
        if isLoggable(level: level) {
            let record = LogRecord(level: level,
                                   message: message,
                                   context: context,
                                   timestamp: Date(),
                                   file: file,
                                   function: function,
                                   line: line)
            log(record)
        }
    }
    
    /// Equivalent to `log(level: .severe, ...)`.
    public func severe(_ message: String,
                       context: CustomStringConvertible? = nil,
                       file: String = #file,
                       function: String = #function,
                       line: Int = #line) {
        log(level: .severe, message: message, context: context,
            file: file, function: function, line: line)
    }
    
    /// Equivalent to `log(level: .warning, ...)`.
    public func warning(_ message: String,
                        context: CustomStringConvertible? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log(level: .warning, message: message, context: context,
            file: file, function: function, line: line)
    }
    
    /// Equivalent to `log(level: .info, ...)`.
    public func info(_ message: String,
                        context: CustomStringConvertible? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log(level: .info, message: message, context: context,
            file: file, function: function, line: line)
    }
    
    /// Equivalent to `log(level: .fine, ...)`.
    public func fine(_ message: String,
                        context: CustomStringConvertible? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log(level: .fine, message: message, context: context,
            file: file, function: function, line: line)
    }
    
    /// Equivalent to `log(level: .finer, ...)`.
    public func finer(_ message: String,
                        context: CustomStringConvertible? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log(level: .finer, message: message, context: context,
            file: file, function: function, line: line)
    }
    
    /// Equivalent to `log(level: .finest, ...)`.
    public func finest(_ message: String,
                        context: CustomStringConvertible? = nil,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        log(level: .finest, message: message, context: context,
            file: file, function: function, line: line)
    }
}

// EOF
