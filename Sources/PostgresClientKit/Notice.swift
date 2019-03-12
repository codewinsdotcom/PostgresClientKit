//
//  Notice.swift
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

public struct Notice: CustomStringConvertible {
    
    public let localizedSeverity: String?
    public let severity: String?
    public let code: String?
    public let message: String?
    public let detail: String?
    public let hint: String?
    public let position: String?
    public let internalPosition: String?
    public let internalQuery: String?
    public let context: String?
    public let schema: String?
    public let table: String?
    public let column: String?
    public let dataType: String?
    public let constraintName: String?
    public let file: String?
    public let line: String?
    public let routine: String?
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    public var description: String {
        return "FIXME"
    }
}

// EOF
