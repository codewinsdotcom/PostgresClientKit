//
//  TestEnvironment.swift
//  PostgresClientKit
//
//  Copyright 2020 David Pitfield and the PostgresClientKit contributors
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

/// The configuration for unit testing.
///
/// Edit the properties' default values to reflect your environment.
struct TestEnvironment {
    
    /// The hostname or IP address of the Postgres server.
    let postgresHost = "127.0.0.1"
    
    /// The port number of the Postgres server.
    let postgresPort = 5432
    
    /// The name of the database on the Postgres server.
    let postgresDatabase = "postgresclientkittest"
    
    /// The username of a Postgres user who can connect by `Credential.trust`.
    let terryUsername = "terry_postgresclientkittest"
    
    /// The password of the Postgres user identified by `terryUsername`.
    let terryPassword = "welcome1"
    
    /// The username of a Postgres user who can connect by `Credential.cleartextPassword`.
    let charlieUsername = "charlie_postgresclientkittest"

    /// The password of the Postgres user identified by `charlieUsername`.
    let charliePassword = "welcome1"
    
    /// The username of a Postgres user who can connect by `Credential.md5Password`.
    let maryUsername = "mary_postgresclientkittest"

    /// The password of the Postgres user identified by `maryUsername`.
    let maryPassword = "welcome1"
    
    
    /// The current test environment.
    static let current = TestEnvironment()
}

// EOF
