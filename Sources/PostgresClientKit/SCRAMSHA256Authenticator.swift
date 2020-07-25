//
//  SCRAMSHA256Authenticator.swift
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

import Foundation

/// Performs SCRAM-SHA-256 authentication (RFC 7677).
internal class SCRAMSHA256Authenticator {
    
    /// Creates a `SCRAMSHA256Authenticator`.
    ///
    /// - Parameters:
    ///   - user: the Postgres username
    ///   - password: the password for that user
    ///   - cnonce: the nonce, or nil to generate a random nonce
    internal init(user: String, password: String, cnonce: String? = nil) {
        
        self.user = user
        self.password = password
        
        // The Postgres server generates a nonce by base64 encoding 18 random bytes.
        // If a nonce is not the supplied, we do the same thing here.
        self.cnonce = cnonce ??
            Data((0..<18).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }).base64EncodedString()
        
        // We don't currently support channel binding.
        selectedChannelBinding = .notSupportedByClient
    }
    
    /// Prepares the `client-first-message`.
    ///
    /// - Throws: `PostgresError` if the operation fails
    /// - Returns: the `client-first-message`
    internal func prepareClientFirstMessage() throws -> String {
        
        precondition(state == .start)
        
        let message = try clientFirstMessage()
        state = .sentClientFirstMessage
        
        return message
    }
    
    /// Processes the `server-first-message`.
    ///
    /// - Parameter serverFirstMessage: the `server-first-message`
    /// - Throws: `PostgresError` if the operation fails
    internal func processServerFirstMessage(_ serverFirstMessage: String) throws {
        
        precondition(state == .sentClientFirstMessage)
        
        let parser = AttributeValuesParser(message: serverFirstMessage)
        
        guard let (nonceAttribute, nonce) = try parser.nextAttributeValue(),
            nonceAttribute == "r" else {
                throw PostgresError.serverError(
                    description: "received malformed SASL message from server: \(serverFirstMessage)")
        }
        
        if !nonce.starts(with: cnonce) {
            throw PostgresError.serverError(description: "response contained incorrect nonce")
        }
        
        guard let (saltAttribute, saltBase64) = try parser.nextAttributeValue(),
            saltAttribute == "s",
            let salt = Data(base64Encoded: saltBase64) else {
                throw PostgresError.serverError(
                    description: "received malformed SASL message from server: \(serverFirstMessage)")
        }
        
        guard let (iterationCountAttribute, iterationCountString) = try parser.nextAttributeValue(),
            iterationCountAttribute == "i",
            let iterationCount = Int(iterationCountString),
            iterationCount > 0 else {
                throw PostgresError.serverError(
                    description: "received malformed SASL message from server: \(serverFirstMessage)")
        }
        
        self.serverFirstMessage = serverFirstMessage
        self.snonce = nonce
        self.salt = salt
        self.iterationCount = iterationCount
        
        state = .receivedServerFirstMessage
    }
    
    /// Prepares the `client-final-message`.
    ///
    /// - Throws: `PostgresError` if the operation fails
    /// - Returns: the `client-final-message`
    internal func prepareClientFinalMessage() throws -> String {
        
        precondition(state == .receivedServerFirstMessage)
        
        try computeProof()
        let message = clientFinalMessage()
        state = .sentClientFinalMessage
        
        return message
    }
    
    /// Processes the `server-final-message`.
    ///
    /// - Parameter serverFinalMessage: the `server-final-message`
    /// - Throws: `PostgresError` if the operation fails
    internal func processServerFinalMessage(_ serverFinalMessage: String) throws {
     
        precondition(state == .sentClientFinalMessage)
        
        let parser = AttributeValuesParser(message: serverFinalMessage)
        
        guard let (nonceAttribute, verifier) = try parser.nextAttributeValue(),
            nonceAttribute == "v" else {
                throw PostgresError.serverError(
                    description: "received malformed SASL message from server: \(serverFinalMessage)")
        }
        
        if verifier != serverSignature!.base64EncodedString() {
            throw PostgresError.serverError(description: "response contained incorrect verifier")
        }
        
        state = .receivedServerFinalMessage
    }
    
    /// A SCRAM channel binding.
    internal enum ChannelBinding {
        
        case notSupportedByClient
        case notSupportedByServer
        case requiredByClient(channelBindingName: String, channelBindingData: Data)
        
        fileprivate var gs2CbindFlag: String {
            switch self {
            case .notSupportedByClient: return "n"
            case .notSupportedByServer: return "y"
            case .requiredByClient(let channelBindingName, _): return "p=\(channelBindingName)"
            }
        }
    }
    
    /// Current state of this authenticator.
    internal enum State {
        case start
        case sentClientFirstMessage
        case receivedServerFirstMessage
        case sentClientFinalMessage
        case receivedServerFinalMessage
    }
    
    internal private(set) var state = State.start
    

    //
    // MARK: Internal implementation
    //
    
    /// A parser for comma-delimited sequences of RFC 5802 `attr-val` items.
    private class AttributeValuesParser {
        
        fileprivate init(message: String) {
            self.message = message
            self.attributeValues = message.split(separator: ",", omittingEmptySubsequences: false)
        }
        
        private let message: String
        private let attributeValues: [String.SubSequence]
        private var index = 0

        fileprivate func nextAttributeValue() throws -> (attribute: String, value: String)? {

            if index == attributeValues.count { return nil }

            let av = attributeValues[index]
            index += 1
            
            let terms = av.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            
            if terms.count != 2 || terms[0].isEmpty || terms[1].isEmpty {
                throw PostgresError.serverError(
                    description: "received malformed SASL message from server: \(message)")
            }
            
            let attribute = String(terms[0])
            let value = String(terms[1])
            
            return (attribute, value)
        }
    }
    
    
    //
    // MARK: Internal state
    //
    
    // Inputs supplied by the API consumer
    private let user: String
    private let password: String
    private let cnonce: String
    private let selectedChannelBinding: ChannelBinding
    
    // State captured from the server-first-message
    private var serverFirstMessage: String?
    private var snonce: String?
    private var salt: Data?
    private var iterationCount: Int?
    
    // State generated by the client-final-message.
    private var proof: String?
    private var serverSignature: Data?
    
    
    //
    // MARK: RFC 5802 Section 2.2
    //
    
    private func H(data: Data) -> Data {
        return Crypto.sha256(data: data)
    }
    
    private func HMAC(key: Data, str: Data) -> Data {
        return Crypto.hmacSHA256(key: key, message: str)
    }
    
    private func Hi(str: Data, salt: Data, i iterationCount: Int) -> Data {
        return Crypto.pbkdf2HMACSHA256(password: str, salt: salt, iterationCount: iterationCount)
    }
    
    
    //
    // MARK: RFC 5802 Section 3
    //
    
    private func computeProof() throws {
        
        let normalizedPassword: Data
        
        do {
            normalizedPassword = try Data(password.saslPrep(stringType: .storedString).utf8)
        } catch is String.SASLPrepError {
            throw PostgresError.invalidPasswordString // don't leak details
        }
        
        let saltedPassword = Hi(str: normalizedPassword, salt: salt!, i: iterationCount!)
        let clientKey = HMAC(key: saltedPassword, str: Data("Client Key".utf8))
        let storedKey = H(data: clientKey)

        let authMessage = try clientFirstMessageBare() + "," +
            serverFirstMessage! + "," +
            clientFinalMessageWithoutProof()
        
        let clientSignature = HMAC(key: storedKey, str: Data(authMessage.utf8))
        let clientProof = Data(clientKey.enumerated().map { $1 ^ clientSignature[$0] })
        proof = "p=" + clientProof.base64EncodedString()

        let serverKey = HMAC(key: saltedPassword, str: Data("Server Key".utf8))
        serverSignature = HMAC(key: serverKey, str: Data(authMessage.utf8))
    }
    
    
    //
    // MARK: RFC 5802 Section 7
    //
    // These functions correspond to ABNF productions in Section 7.
    //
    
    private func saslname() throws -> String {
        do {
            return try user.saslPrep(stringType: .storedString)
                .replacingOccurrences(of: "=", with: "=3D")
                .replacingOccurrences(of: ",", with: "=2C")
        } catch is String.SASLPrepError {
            throw PostgresError.invalidUsernameString // don't leak details
        }
    }
    
    private func optionalAuthzid() -> String {
        return "" // unused by Postgres
    }
    
    private func gs2CbindFlag() -> String {
        return selectedChannelBinding.gs2CbindFlag
    }
    
    private func gs2Header() -> String {
        return gs2CbindFlag() + "," + optionalAuthzid() + ","
    }
    
    private func username() throws -> String {
        return try "n=" + saslname()
    }
    
    private func optionalReservedMextComma() -> String {
        return "" // unused by Postgres
    }
    
    private func channelBinding() -> String {
        return "c=" + cbindInput().base64EncodedString()
    }
    
    private func clientNonce() -> String {
        return "r=" + cnonce
    }
    
    private func serverNonce() -> String {
        return "r=" + snonce!
    }
    
    private func clientFirstMessageBare() throws -> String {
        return try optionalReservedMextComma() +
            username() + "," + clientNonce() + optionalCommaExtensions()
    }
    
    private func clientFirstMessage() throws -> String {
        return try gs2Header() + clientFirstMessageBare()
    }
    
    private func clientFinalMessageWithoutProof() -> String {
        return channelBinding() + "," + serverNonce() + optionalCommaExtensions()
    }
    
    private func clientFinalMessage() -> String {
        return clientFinalMessageWithoutProof() + "," + proof!
    }
    
    private func optionalCommaExtensions() -> String {
        return "" // unused by Postgres
    }
    
    private func cbindData() -> Data {
        
        switch selectedChannelBinding {
            
        case let .requiredByClient(_, channelBindingData):
            return channelBindingData
            
        default:
            return Data()
        }
    }
    
    private func cbindInput() -> Data {
        var data = Data(gs2Header().utf8)
        data.append(cbindData())
        return data
    }
}

// EOF
