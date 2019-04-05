//
//  LogRecord.swift
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

/// Describes an event to be logged.
public struct LogRecord {
    
    /// Creates a `LogRecord`.
    ///
    /// - Parameters:
    ///   - level: the log level that reflects the importance of the event
    ///   - message: a message describing this event
    ///   - context: the context of the event, such as a session or connection identifier
    ///   - timestamp: the timestamp of the event
    ///   - file: the name of the file that logged the event
    ///   - function: the name of the function that logged the event
    ///   - line: the line number that logged the event
    public init(level: LogLevel,
                message: CustomStringConvertible,
                context: CustomStringConvertible?,
                timestamp: Date,
                file: String,
                function: String,
                line: Int) {
        
        self.level = level
        self.message = message
        self.context = context
        self.timestamp = timestamp
        self.file = file
        self.function = function
        self.line = line
    }
    
    /// The log level that reflects the importance of the event.
    public let level: LogLevel
    
    /// A message describing this event.
    public let message: CustomStringConvertible
    
    /// The context of the event, such as a session or connection identifier.
    public let context: CustomStringConvertible?
    
    /// The timestamp of the event.
    public let timestamp: Date
    
    /// The name of the file that logged the event.
    public let file: String
    
    /// The name of the function that logged the event.
    public let function: String
    
    /// The line number that logged the event.
    public let line: Int
}

// EOF
