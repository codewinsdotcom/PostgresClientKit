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
    
    /// The parameter value desired by PostgresClientKit.
    internal let value: String
    
    /// Whether PostgresClientKit sets the value of this parameter in creating a `Connection`.
    internal let isSetWhenConnecting: Bool
    
    /// Whether PostgresClientKit checks the value of this parameter when it receives a
    /// `ParameterStatusResponse`.
    internal let isCheckedUponParameterStatusResponse: Bool
    
    /// The parameters of interest to PostgresClientKit.
    internal static let values = [
        
        // PostgresClientKit requires strings received from the Postgres server to be UTF8 format.
        Parameter(name: "client_encoding",
                  value: "UTF8",
                  isSetWhenConnecting: true,
                  isCheckedUponParameterStatusResponse: true),
        
        // PostgresClientKit requires timestamps, dates, and times received from the Postgres server
        // to be ISO-8601 format.
        Parameter(name: "DateStyle",
                  value: "ISO, MDY",
                  isSetWhenConnecting: true,
                  isCheckedUponParameterStatusResponse: true),
        
        // PostgresClientKit requires timestamps and times received from the Postgres server to be
        // in the UTC/GMT time zone.
        Parameter(name: "TimeZone",
                  value: "GMT",
                  isSetWhenConnecting: true,
                  isCheckedUponParameterStatusResponse: true),
        
        // PostgresClientKit requires `bytea` values received from the Postgres server to be hex
        // encoded.
        Parameter(name: "bytea_output",
                  value: "hex",
                  isSetWhenConnecting: true,
                  isCheckedUponParameterStatusResponse: true),
    ]
    
    /// Checks whether the parameter in the specified `ParameterStatusResponse` is required by
    /// PostgresClientKit to have a certain value and, if so, whether it has that value.
    ///
    /// - Parameter response: the response to check
    /// - Throws: `PostgresError.invalidParameterValue` if the parameter does not have the required
    ///     value
    internal static func checkParameterStatusResponse(_ response: ParameterStatusResponse) throws {
        
        if let parameter = values.first(where: {
            $0.name == response.name
                && $0.isCheckedUponParameterStatusResponse
                && $0.value != response.value } ) {
            
            throw PostgresError.invalidParameterValue(name: response.name,
                                                      value: response.value,
                                                      requiredValue: parameter.value)
        }
    }
}

/// EOF
