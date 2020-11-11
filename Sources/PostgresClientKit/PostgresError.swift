//
//  PostgresError.swift
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

/// Errors thrown by PostgresClientKit.
public enum PostgresError: Error {
    
    /// The Postgres server requires a `Credential.cleartextPassword` for authentication.
    case cleartextPasswordCredentialRequired
    
    /// An attempt was made to operate on a closed connection.
    case connectionClosed
    
    /// An attempt was made to operate on a closed connection pool.
    case connectionPoolClosed
    
    /// An attempt was made to operate on a closed cursor.
    case cursorClosed
    
    /// The Postgres server has a parameter set to a value incompatible with PostgresClientKit.
    case invalidParameterValue(name: String, value: String, allowedValues: [String])
    
    /// The specified username does not meet the SCRAM-SHA-256 requirements for a username.
    case invalidUsernameString
    
    /// The specified password does not meet the SCRAM-SHA-256 requirements for a password.
    case invalidPasswordString
    
    /// The Postgres server requires a `Credential.md5Password` for authentication.
    case md5PasswordCredentialRequired
    
    /// The Postgres server requires a `Credential.scramSHA256` for authentication.
    case scramSHA256CredentialRequired
    
    /// The Postgres server reported an internal error or returned an invalid response.
    case serverError(description: String)
    
    /// A network error occurred in communicating with the Postgres server.
    case socketError(cause: Error)
    
    /// The Postgres server reported a SQL error.
    case sqlError(notice: Notice)
    
    /// An error occurred in establishing SSL/TLS encryption.
    case sslError(cause: Error)
    
    /// The Postgres server does not support SSL/TLS.
    case sslNotSupported
    
    /// An attempt was made to operate on a closed statement.
    case statementClosed
    
    /// The request for a connection failed because a connection was not allocated before the
    /// request timed out.
    ///
    /// - SeeAlso: `ConnectionPoolConfiguration.pendingRequestTimeout`
    case timedOutAcquiringConnection
    
    /// The request for a connection failed because the request backlog was too large.
    ///
    /// - SeeAlso: `ConnectionPoolConfiguration.maximumPendingRequests`
    case tooManyRequestsForConnections
    
    /// The Postgres server requires a `Credential.trust` for authentication.
    case trustCredentialRequired
    
    /// The authentication type required by the Postgres server is not supported by
    /// PostgresClientKit.
    case unsupportedAuthenticationType(authenticationType: String)
    
    /// The value could not be converted to the requested type.
    case valueConversionError(value: PostgresValue, type: Any.Type)
    
    /// The value is `nil`.
    case valueIsNil
}

// EOF
