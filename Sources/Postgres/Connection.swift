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
    
    /// Reads an unsigned 8-bit integer from Postgres.
    ///
    /// - Returns: the value
    /// - Throws: `PostgresError` if the operation fails
    private func readUInt8() throws -> UInt8 {
        
        if readBufferPosition == readBuffer.count {
            try refillReadBuffer()
        }
        
        let byte = readBuffer[readBufferPosition]
        readBufferPosition += 1
        
        return byte
    }
    
    /// Reads data from Postgres.
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
        
        return data
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
    // MARK: CustomStringConvertible
    //
    
    /// A short string that identifies this connection.
    public let description = "Connection-\(Postgres.nextId())"
}

// EOF
