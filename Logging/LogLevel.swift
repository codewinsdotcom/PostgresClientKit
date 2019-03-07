//
//  LogLevel.swift
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

/// The available log levels.
public enum LogLevel: Int, Comparable {
    
    /// A failure.
    case severe = 1000
    
    /// A potential problem.
    case warning = 900
    
    /// An informational message.
    case info = 800
    
    /// A debug messsage.
    case fine = 500
    
    /// A more detailed debug message.
    case finer = 400
    
    /// An even more detailed debug message.
    case finest = 300
    
    /// As the value of `Logger.level`, disables all logging.
    case off = 10000
    
    /// As the value of `Logger.level`, logs all log records.
    case all = 0
    
    
    //
    // MARK: Comparable
    //
    
    /// Compares the `rawValue` of `lhs` and `rhs`.
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// EOF
