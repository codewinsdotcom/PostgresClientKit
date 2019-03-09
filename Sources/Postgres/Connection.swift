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

public class Connection: CustomStringConvertible {
    
    public init(configuration: ConnectionConfiguration,
                delegate: ConnectionDelegate? = nil) throws {
        
        fatalError()
    }
    
    public weak var delegate: ConnectionDelegate?
    
    public func prepareStatement(text: String) throws -> Statement {
        fatalError()
    }
    
    public func beginTransaction() throws { }
    public func commitTransaction() throws { }
    public func rollbackTransaction() throws { }
    
    public var isClosed: Bool {
        return false
    }
    
    public func close() { }
    
    
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
    
    /// The body of a response (everything after the bytes indicating the response length).
    internal class ResponseBody {
        
        /// Creates an instance.
        ///
        /// - Parameters:
        ///   - responseType: the response type
        ///   - responseLength: the response length, in bytes
        ///   - connection: the connection
        private init(responseType: Character, responseLength: Int, connection: Connection) {
            
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
        internal func readUInt8() throws -> UInt8 {
            
            if bytesRemaining == 0 {
                throw PostgresError.serverError(description: "response too short")
            }
            
            let byte = try connection.readUInt8()
            bytesRemaining -= 1
            
            return byte
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
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this connection.
    public let description = "Connection-\(Postgres.nextId())"
}

// EOF
