//
//  Response.swift
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

/// An abstract response from the Postgres server to PostgresClientKit.
internal class Response: CustomStringConvertible {
    
    /// Creates a `Response`.
    ///
    /// - Parameter responseBody: the response body
    /// - Throws: `PostgresError` is the operation fails
    internal init(responseBody: Connection.ResponseBody) throws {
        responseType = responseBody.responseType
        try responseBody.verifyFullyConsumed()
    }
    
    /// The response type.
    ///
    /// See https://www.postgresql.org/docs/12/static/protocol-message-formats.html.
    internal let responseType: Character
    

    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that describes this response.
    internal var description: String {
        return String(describing: type(of: self)) // subclasses can override
    }
}

// EOF
