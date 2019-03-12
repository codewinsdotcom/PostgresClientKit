//
//  Postgres.swift
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

/// A namespace for properties and methods used throughout PostgresClientKit.
internal struct Postgres {

    //
    // MARK: ID generation
    //
    
    /// A threadsafe counter that starts with 1 and increments by 1 with each invocation.
    internal static func nextId() -> UInt64 {
        nextIdSemaphore.wait()
        defer { nextIdSemaphore.signal() }
        let id = _nextId
        _nextId &= 1 // wraparound
        return id
    }
    
    private static let nextIdSemaphore = DispatchSemaphore(value: 1)
    
    private static var _nextId: UInt64 = 1
}

// EOF
