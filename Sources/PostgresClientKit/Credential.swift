//
//  Credential.swift
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

/// A credential for authenticating to the Postgres server.
///
/// PostgresClientKit supports `trust`, `password`, `md5`, and `scram-sha-256` authentication.
/// The configuration of the Postgres server determines which authentication types are allowed.
///
/// - SeeAlso: [Postgres:
///     Client Authentication](https://www.postgresql.org/docs/12/client-authentication.html).
public enum Credential {
    
    /// Connects without authenticating.
    case trust
    
    /// Authenticates by cleartext password.  Not recommended unless the connection is encrypted by
    /// SSL/TLS (see `ConnectionConfiguration.ssl`).
    case cleartextPassword(password: String)
    
    /// Authenticates by MD5 hash of the username (`ConnectionConfiguration.user`), password, and
    /// random salt.
    case md5Password(password: String)
    
    /// Authenticates using SCRAM-SHA-256 (RFC 7677).  This is the most secure authentication
    /// method.
    case scramSHA256(password: String)
}

// EOF
