//
//  Parameter.swift
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

/// A Postgres server configuration parameter.
///
/// In creating a `Connection` to the Postgres server, PostgresClientKit sets the values of certain
/// parameters.
///
/// Additionally, when PostgresClientKit receives a `ParameterStatusResponse` from the Postgres
/// server, it checks the values of certain parameters.
///
/// Together, these actions help ensure a predictable environment for PostgresClientKit.
internal struct Parameter {
    
    /// The parameter name.
    internal let name: String
    
    /// The parameter values allowed by PostgresClientKit, or `nil` for any value.
    internal let allowedValues: [String]?
    
    /// The parameter value set by PostgresClientKit in creating a `Connection`, or `nil` to not
    /// set a value.
    internal let valueSetWhenConnecting: String?
    
    /// The parameters of interest to PostgresClientKit.
    internal static let values = [
        
        // PostgresClientKit requires strings received from the Postgres server to be UTF8 format.
        Parameter(name: "client_encoding",
                  allowedValues: [ "UTF8" ],
                  valueSetWhenConnecting: "UTF8"),
        
        // PostgresClientKit requires timestamps, dates, and times received from the Postgres server
        // to be ISO-8601 format.
        Parameter(name: "DateStyle",
                  allowedValues: [ "ISO, MDY", "ISO, DMY", "ISO, YMD" ],
                  valueSetWhenConnecting: "ISO, MDY"),
        
        // By default, PostgresClientKit configures the connection so that timestamps and times
        // received from the Postgres server are in the UTC/GMT time zone.  This is for backward
        // compatibility with earlier releases.  See #31.
        Parameter(name: "TimeZone",
                  allowedValues: nil,
                  valueSetWhenConnecting: "GMT"),

        // PostgresClientKit requires `bytea` values received from the Postgres server to be hex
        // encoded.
        Parameter(name: "bytea_output",
                  allowedValues: [ "hex" ],
                  valueSetWhenConnecting: "hex"),
    ]
    
    /// Checks whether the parameter in the specified `ParameterStatusResponse` is constrained by
    /// PostgresClientKit to certain values and, if so, whether that constraint is satisfied.
    ///
    /// - Parameter response: the response to check
    /// - Throws: `PostgresError.invalidParameterValue` if the parameter does not have an allowed
    ///     value
    internal static func checkParameterStatusResponse(_ response: ParameterStatusResponse,
                                                      connection: Connection) throws {
        
        if let parameter = values.first(where: {
            $0.name == response.name
                && $0.allowedValues != nil
                && !$0.allowedValues!.contains(response.value) } ) {
            
            let allowedValues = parameter.allowedValues!
            
            connection.log(
                .warning,
                "Invalid value for Postgres parameter \(response.name): " +
                    "\(response.value) (allowedValues \(allowedValues)); closing connection")
            
            // The invalid parameter change already ocurred.  This connection is toast.
            connection.close()
            
            throw PostgresError.invalidParameterValue(name: response.name,
                                                      value: response.value,
                                                      allowedValues: allowedValues)
        }
    }
}

/// EOF
