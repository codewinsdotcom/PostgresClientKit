//
//  AuthenticationResponse.swift
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

internal class AuthenticationResponse: Response {
    
    internal class func parse(responseBody: Connection.ResponseBody) throws
        -> AuthenticationResponse {
        
        let connection = responseBody.connection
        let authenticationType = try responseBody.readUInt32()
        
        switch authenticationType {
            
        case 0:
            return try AuthenticationOKResponse(responseBody: responseBody)
            
        case 2:
            connection.log(.warning, "Unsupported authentication type: AuthenticationKerberosV5")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "AuthenticationKerberosV5")
            
        case 3:
            return try AuthenticationCleartextPasswordResponse(responseBody: responseBody)
            
        case 5:
            return try AuthenticationMD5PasswordResponse(responseBody: responseBody)
            
        case 6:
            connection.log(.warning, "Unsupported authentication type: AuthenticationSCMCredential")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "AuthenticationSCMCredential")
            
        case 7:
            connection.log(.warning, "Unsupported authentication type: AuthenticationGSS")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "AuthenticationGSS")
            
        case 8:
            connection.log(.warning, "Unsupported authentication type: AuthenticationGSSContinue")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "AuthenticationGSSContinue")
            
        case 9:
            connection.log(.warning, "Unsupported authentication type: AuthenticationSSPI")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "AuthenticationSSPI")
            
        case 10:
            return try AuthenticationSASLResponse(responseBody: responseBody)

        case 11:
            return try AuthenticationSASLContinueResponse(responseBody: responseBody)
            
        case 12:
            return try AuthenticationSASLFinalResponse(responseBody: responseBody)
            
        default:
            connection.log(.warning, "Unsupported authentication type: \(authenticationType)")
            
            throw PostgresError.unsupportedAuthenticationType(
                authenticationType: "\(authenticationType)")
        }
    }
}

// EOF
