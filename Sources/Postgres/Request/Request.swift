//
//  Request.swift
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

/// An abstract request from the client to the Postgres server.
internal class Request: CustomStringConvertible {
    
    /// The request type.
    ///
    /// See https://www.postgresql.org/docs/10/static/protocol-message-formats.html.
    private var requestType: Character? {
        fatalError("Request subclass must override requestType property")
    }
    
    /// The body of the request (everything after the bytes indicating the request length).
    private var body: Data {
        fatalError("Request subclass must override body property")
    }
    
    /// The entire request, including the bytes indicating its type and length.
    final internal var data: Data {
        
        var request = Data()
        
        if let requestType = requestType {
            request.append(String(requestType).data(using: .ascii)!)
        }
        
        let body = self.body
        let requestLength = body.count + 4 // requestLength includes the 4-byte request length
        request.append(UInt32(requestLength).data)
        request.append(body)
        
        return request
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that describes this request.
    internal var description: String {
        return String(describing: type(of: self)) // subclasses can override
    }
}

private extension UInt32 {
    
    /// The big-endian representation.
    var data: Data {
        var value = bigEndian
        return Data(bytes: &value, count: 4)
    }
}

// EOF
