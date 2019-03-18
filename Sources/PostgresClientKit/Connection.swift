//
//  Connection.swift
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
import Socket
import SSLService

public class Connection: CustomStringConvertible {
    
    //
    // MARK: Connection lifecycle
    //
    
    /// Creates a connection.
    ///
    /// - Parameters:
    ///   - configuration: the connection configuration
    ///   - delegate: the optional delegate for the connection
    /// - Throws: `PostgresError` if the operation fails
    public init(configuration: ConnectionConfiguration,
                delegate: ConnectionDelegate? = nil) throws {
        
        var success = false
        
        self.delegate = delegate
        
        let host = configuration.host
        let port = configuration.port

        do {
            socket = try Socket.create()
            log(.finer, "Created socket")
        } catch {
            throw PostgresError.socketError(cause: error)
        }

        defer {
            if !success {
                log(.finer, "Closing socket")
                socket.close()
            }
        }

        do {
            log(.fine, "Opening connection to port \(port) on host \(host)")
            try socket.connect(to: host, port: Int32(port))
        } catch {
            throw PostgresError.socketError(cause: error)
        }
        
        if configuration.ssl {
            log(.finer, "Requesting SSL/TLS encryption")

            let sslRequest = SSLRequest()
            try sendRequest(sslRequest)
            let sslCode = try readASCIICharacter()
            
            guard sslCode == "S" else {
                throw PostgresError.sslNotSupported
            }
            
            let sslConfig = SSLService.Configuration()
            let sslService = try SSLService(usingConfiguration: sslConfig)!
            socket.delegate = sslService
            try sslService.initialize(asServer: false)
            try sslService.onConnect(socket: socket)
            
            log(.fine, "Successfully negotiated SSL/TLS encryption")
        }
        
        let user = configuration.user
        let database = configuration.database
        
        log(.fine, "Connecting to database \(database) as user \(user)")
        
        let startupRequest = StartupRequest(user: user, database: database)
        try sendRequest(startupRequest)
        
        authentication:
        while true {
            let authenticationResponse = try receiveResponse(type: AuthenticationResponse.self)
            
            switch authenticationResponse {
                
            case is AuthenticationOKResponse:
                break authentication
                
            case is AuthenticationCleartextPasswordResponse:
                
                guard case let .cleartextPassword(password) = configuration.credential else {
                    throw PostgresError.cleartextPasswordCredentialRequired
                }
                
                let passwordMessageRequest = PasswordMessageRequest(password: password)
                try sendRequest(passwordMessageRequest)
                
            case let response as AuthenticationMD5PasswordResponse:
                
                guard case let .md5Password(password) = configuration.credential else {
                    throw PostgresError.md5PasswordCredentialRequired
                }
                
                var passwordUser = password.data
                passwordUser.append(user.data)
                
                let passwordUserHash = Postgres.md5(data: passwordUser)
                    .map { String(format: "%02x", $0) }.joined()
                
                var salted = passwordUserHash.data
                salted.append(response.salt.data)
                
                let saltedHash = Postgres.md5(data: salted)
                    .map { String(format: "%02x", $0) }.joined()
                
                let passwordMessageRequest = PasswordMessageRequest(password: "md5" + saltedHash)
                try sendRequest(passwordMessageRequest)

            default:
                fatalError("\(authenticationResponse) not handled when connecting")
            }
        }
        
        try receiveResponse(type: ReadyForQueryResponse.self)
        
        log(.fine, "Successfully connected")
        success = true
    }
    
    public weak var delegate: ConnectionDelegate?
    
    public var isClosed: Bool {
        return !socket.isConnected
    }
    
    public func close() {
        
        if !isClosed {
            log(.fine, "Closing connection")
            let terminateRequest = TerminateRequest()
            try? sendRequest(terminateRequest) // consumes any Error
            
            log(.finer, "Closing socket")
            socket.close()
            
            log(.fine, "Connection closed")
        }
    }
    
    deinit {
        close()
    }
    

    //
    // MARK: Statement execution
    //
    
    public func prepareStatement(text: String) throws -> Statement {
        fatalError("FIXME: implement")
    }
    
    public func beginTransaction() throws {
        fatalError("FIXME: implement")
    }
    
    public func commitTransaction() throws {
        fatalError("FIXME: implement")
    }
    
    public func rollbackTransaction() throws {
        fatalError("FIXME: implement")
    }
    
    
    //
    // MARK: Request processing
    //
    
    private func sendRequest(_ request: Request) throws {
        
        log(.finer, "Sending \(request)")

        do {
            try socket.write(from: request.data())
        } catch {
            throw PostgresError.socketError(cause: error)
        }
    }
    
    
    //
    // MARK: Response processing
    //
    
    @discardableResult private func receiveResponse<T: Response>(type: T.Type? = nil) throws -> T {
        
        while true {
            
            let responseType = try readASCIICharacter()
            
            // The response length includes itself (4 bytes) but excludes the response type (1 byte).
            let responseLength = try readUInt32()
            
            let responseBody = ResponseBody(responseType: responseType,
                                            responseLength: Int(responseLength),
                                            connection: self)
            
            let response: Response
            
            switch responseType {
                
            case "E": response = try ErrorResponse(responseBody: responseBody)
            case "K": response = try BackendKeyDataResponse(responseBody: responseBody)
            case "N": response = try NoticeResponse(responseBody: responseBody)
            case "R": response = try AuthenticationResponse.parse(responseBody: responseBody)
            case "S": response = try ParameterStatusResponse(responseBody: responseBody)
            case "Z": response = try ReadyForQueryResponse(responseBody: responseBody)
                
            default:
                throw PostgresError.serverError(
                    description: "unrecognized response type '\(responseType)'")
            }
            
            log(.finer, "Received \(response)")
            
            switch response {
                
            case is BackendKeyDataResponse:
                continue // don't need this, since we don't support CancelRequest
                
            case let errorResponse as ErrorResponse:
                throw PostgresError.sqlError(notice: errorResponse.notice)
                
            case let noticeResponse as NoticeResponse:
                delegate?.connection(self, didReceiveNotice: noticeResponse.notice)
                
            case let parameterStatusResponse as ParameterStatusResponse:
                
                delegate?.connection(
                    self,
                    didReceiveParameterStatus: (name: parameterStatusResponse.name,
                                                value: parameterStatusResponse.value))
                
                try Parameter.checkParameterStatusResponse(parameterStatusResponse)
                
            case is T:
                return response as! T
                
            default:
                throw PostgresError.serverError(description: "unexpected response type '\(responseType)'")
            }
        }
    }
    
    /// The body of a response (everything after the bytes indicating the response length).
    internal class ResponseBody {
        
        /// Creates an instance.
        ///
        /// - Parameters:
        ///   - responseType: the response type
        ///   - responseLength: the response length, in bytes
        ///   - connection: the connection
        fileprivate init(responseType: Character, responseLength: Int, connection: Connection) {
            
            self.responseType = responseType
            
            // responseLength includes the 4-byte response length
            self.bytesRemaining = responseLength - 4
            
            self.connection = connection
        }
        
        internal let responseType: Character
        private var bytesRemaining: Int
        private let connection: Connection
        
        /// Reads an unsigned 8-bit integer without consuming it.
        ///
        /// - Returns: the value
        /// - Throws: `PostgresError` if the operation fails
        internal func peekUInt8() throws -> UInt8 {
            
            if bytesRemaining == 0 {
                throw PostgresError.serverError(description: "response too short")
            }
            
            let byte = try connection.peekUInt8()
            
            return byte
        }
        
        /// Reads an unsigned 8-bit integer.
        ///
        /// - Returns: the value
        /// - Throws: `PostgresError` if the operation fails
        @discardableResult internal func readUInt8() throws -> UInt8 {
            
            if bytesRemaining == 0 {
                throw PostgresError.serverError(description: "response too short")
            }
            
            let byte = try connection.readUInt8()
            bytesRemaining -= 1
            
            return byte
        }
        
        /// Reads an unsigned 32-bit integer.
        ///
        /// - Returns: the value
        /// - Throws: `PostgresError` if the operation fails
        internal func readUInt32() throws -> UInt32 {
            
            let value = try
                UInt32(readUInt8()) << 24 +
                UInt32(readUInt8()) << 16 +
                UInt32(readUInt8()) << 8 +
                UInt32(readUInt8())
            
            return value
        }

        /// Reads the specified number of bytes.
        ///
        /// - Parameter count: the number of bytes to read
        /// - Returns: the data
        /// - Throws: `PostgresError` if the operation fails
        internal func readData(count: Int) throws -> Data {
            
            if bytesRemaining < count {
                throw PostgresError.serverError(description: "response too short")
            }
            
            let data = try connection.readData(count: count)
            bytesRemaining -= data.count
            
            assert(data.count == count)
            
            return data
        }
        
        /// Reads a single ASCII character.
        ///
        /// - Returns: the character
        /// - Throws: `PostgresError` if the operation fails
        internal func readASCIICharacter() throws -> Character {
            
            let c = try Character(Unicode.Scalar(readUInt8()))
            
            return c
        }

        /// Reads a null-terminated UTF8 string.
        ///
        /// - Returns: the string
        /// - Throws: `PostgresError` if the operation fails
        internal func readUTF8String() throws -> String {
            
            var data = Data()
            
            while true {
                let b = try readUInt8()
                
                if b == 0 {
                    break
                }
                
                data.append(b)
            }
            
            guard let s = String(data: data, encoding: .utf8) else {
                throw PostgresError.serverError(description: "response contained invalid UTF8 string")
            }
            
            return s
        }
        
        /// Verifies the response body has been fully consumed.
        ///
        /// - Throws: `PostgresError` if not fully consumed
        internal func verifyFullyConsumed() throws {
            if bytesRemaining != 0 {
                throw PostgresError.serverError(description: "response too long")
            }
        }
    }
    
    
    //
    // MARK: Socket
    //
    
    /// The underlying socket to the Postgres server.
    private let socket: Socket
    
    /// A buffer of data read from Postgres but not yet consumed.
    private var readBuffer = Data()
    
    /// The index of the next byte to consume from the read buffer.
    private var readBufferPosition = 0
    
    /// Reads an unsigned 8-bit integer from Postgres without consuming it.
    ///
    /// - Returns: the value
    /// - Throws: `PostgresError` if the operation fails
    private func peekUInt8() throws -> UInt8 {
        
        if readBufferPosition == readBuffer.count {
            try refillReadBuffer()
        }
        
        let byte = readBuffer[readBufferPosition]
        
        return byte
    }
    
    /// Reads an unsigned 8-bit integer from Postgres.
    ///
    /// - Returns: the value
    /// - Throws: `PostgresError` if the operation fails
    private func readUInt8() throws -> UInt8 {
        
        let byte = try peekUInt8()
        readBufferPosition += 1
        
        return byte
    }
    
    /// Reads an unsigned big-endian 32-bit integer from Postgres.
    ///
    /// - Returns: the value
    /// - Throws: `PostgresError` if the operation fails
    private func readUInt32() throws -> UInt32 {
        
        let value = try
            UInt32(readUInt8()) << 24 +
            UInt32(readUInt8()) << 16 +
            UInt32(readUInt8()) << 8 +
            UInt32(readUInt8())
        
        return value
    }
    
    /// Reads the specified number of bytes from Postgres.
    ///
    /// - Parameter count: the number of bytes to read
    /// - Returns: the data
    /// - Throws: `PostgresError` if the operation fails
    private func readData(count: Int) throws -> Data {
        
        var data = Data()
        
        while data.count < count {
            
            let fromIndex = readBufferPosition
            let toIndex = min(readBufferPosition + count, readBuffer.count)
            let chunk = readBuffer[fromIndex..<toIndex]
            data += chunk
            readBufferPosition += chunk.count
            
            if data.count < count {
                try refillReadBuffer()
            }
        }
        
        assert(data.count == count)
        
        return data
    }
    
    /// Reads a single ASCII character from Postgres.
    ///
    /// - Returns: the character
    /// - Throws: `PostgresError` if the operation fails
    private func readASCIICharacter() throws -> Character {
        
        let c = try Character(Unicode.Scalar(readUInt8()))
        
        return c
    }
    
    private func refillReadBuffer() throws {
        
        assert(readBufferPosition == readBuffer.count)
        
        readBuffer.removeAll()
        readBufferPosition = 0
        
        var readCount = 0
        
        do {
            readCount = try socket.read(into: &readBuffer)
        } catch {
            throw PostgresError.socketError(cause: error)
        }
        
        if readCount == 0 {
            throw PostgresError.serverError(description: "no data available from server")
        }
    }
    
    
    //
    // MARK: Logging
    //
    
    private func log(_ level: LogLevel,
                    _ message: CustomStringConvertible,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        
        Postgres.logger.log(level: level,
                            message: message,
                            context: self,
                            file: file,
                            function: function,
                            line: line)
    }
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this connection.
    public let description = "Connection-\(Postgres.nextId())"
}

// EOF
