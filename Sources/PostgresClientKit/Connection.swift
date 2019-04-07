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

/// A connection to a Postgres server.
///
/// The `ConnectionConfiguration` used to create a `Connection` specifies the hostname and port
/// number of the Postgres server, the user name and database to use, and other characteristics
/// of the connection.
///
/// Connections are used to perform SQL statements.  To perform a SQL statement:
///
/// - Call `Connection.prepareStatement(text:)` to parse the SQL text and return a `Statement`.
/// - Call `Statement.execute(parameterValues:)` to execute the statement and return a `Cursor`.
/// - Iterate over the `Cursor` to retrieve the rows in the result.
/// - Close the `Cursor` and the `Statement` to release resources on the Postgres server.
///
/// A `Statement` can be repeatedly executed, and the values of its parameters can be different
/// each time.  This is more efficient than having the Postgres server repeatedly parse the same
/// SQL text.
///
/// A `Connection` performs no more than one SQL statement at a time.  When
/// `Connection.prepareStatement(text:)` or `Statement.execute(parameterValues:)` is called, any
/// previous `Cursor` for the `Connection` is closed.
///
/// The following methods also close any previous `Cursor` for the `Connection`:
///
/// - `Connection.beginTransaction()`
/// - `Connection.commitTransaction()`
/// - `Connection.rollbackTransaction()`
/// - `Statement.close()`
/// - `Cursor.close()`
///
/// To concurrently perform more than one SQL statement, use multiple connections.
///
/// By default, each `Statement` is executed in its own transaction.  The statement's transaction is
/// automatically rolled back if an error occurs in executing the statement, and is automatically
/// commited upon any of the following events:
///
/// - if there are no rows in the result: upon completion of `Statement.execute()`
/// - if the result has one or more rows: after the final row has been retrieved (in other words,
///   when `Cursor.next()` returns `nil`)
/// - when the `Cursor` is closed (in any of the ways listed above)
///
/// Alternately, transactions can be explicitly demarcated by performing the SQL `BEGIN`, `COMMIT`,
/// and `ROLLBACK` commands (or equivalently, the `Connection.beginTransaction()`,
/// `Connection.commitTransaction()`, and `Connection.rollbackTransaction()` methods).
///
/// No more than one thread may concurrently operate against a `Connection` (including its
/// `Statement` and `Cursor` instances).  However, multiple threads may concurrently operate
/// against different connections.
///
/// When a `Connection` is no longer required, call `Connection.close()` to release its Postgres
/// server resources and close the network socket.  A `Connection` is automatically closed if an
/// unrecoverable error occurs (for example, if the Postgres server closes the network socket).
/// Use `Connection.isClosed` to test whether a `Connection` is closed.
public class Connection: CustomStringConvertible {
    
    //
    // MARK: Connection lifecycle
    //
    
    /// Creates a `Connection`.
    ///
    /// - Parameters:
    ///   - configuration: the configuration for the `Connection`
    ///   - delegate: an optional delegate for the `Connection`
    /// - Throws: `PostgresError` if the operation fails
    public init(configuration: ConnectionConfiguration,
                delegate: ConnectionDelegate? = nil) throws {
        
        var success = false
        
        self.delegate = delegate
        
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
        
        let host = configuration.host
        let port = configuration.port

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
                
                func md5AsHex(data: Data) -> String {
                    return Postgres.md5(data: data).map { String(format: "%02x", $0) }.joined()
                }
                
                // Compute concat('md5', md5(concat(md5(concat(password, username)), random-salt))).
                var passwordUser = password.data
                passwordUser.append(user.data)
                let passwordUserHash = md5AsHex(data: passwordUser)
                
                var salted = passwordUserHash.data
                salted.append(response.salt.data)
                let saltedHash = md5AsHex(data: salted)
                
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
    
    /// An optional delegate for this `Connection`.
    ///
    /// - Note: `Connection` holds a `weak` reference to the delegate.
    public weak var delegate: ConnectionDelegate?
    
    /// Uniquely identifies this `Connection`.  Used in logging.
    private let id = "Connection-\(Postgres.nextId())"

    /// Whether this `Connection` is closed.
    ///
    /// To close a `Connection`, call `close()`.  A `Connection` is also closed if an unrecoverable
    /// error occurs (for example, if the Postgres server closes the network socket).
    public var isClosed: Bool {
        return !socket.isConnected
    }
    
    /// Closes this `Connection`.
    ///
    /// Has no effect if this `Connection` is already closed.
    public func close() {
        if !isClosed {
            log(.fine, "Closing connection")
            cursorState = .closed
            
            let terminateRequest = TerminateRequest()
            try? sendRequest(terminateRequest) // consumes any Error
            
            log(.finer, "Closing socket")
            socket.close()
            
            log(.fine, "Connection closed")
        }
    }
    
    /// Verifies this `Connection` is not closed.
    ///
    /// - Throws: `PostgresError.connectionClosed` if closed
    private func verifyConnectionNotClosed() throws {
        if isClosed {
            throw PostgresError.connectionClosed
        }
    }
    
    /// Invokes `close()`.
    deinit {
        close()
    }
    
    /// Attempts to resynchronize this `Connection`, closing it if resynchronization fails.
    ///
    /// The Postgres server requires resynchronization to be performed after reporting an
    /// `ErrorResponse`.
    private func resyncOrCloseConnection() {
        if !isClosed {
            cursorState = .closed
            
            do {
                let syncRequest = SyncRequest()
                try sendRequest(syncRequest)
                try receiveResponse(type: ReadyForQueryResponse.self)
            } catch {
                log(.warning, "Closing connection due to unrecoverable error: \(error)")
                close()
            }
        }
    }
    

    //
    // MARK: Statement execution
    //
    
    /// Prepares a SQL statement for execution.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Parameter text: the SQL text
    /// - Returns: the prepared `Statement`
    /// - Throws: `PostgresError` if the operation fails
    public func prepareStatement(text: String) throws -> Statement {
        
        let statement = Statement(connection: self, text: text)
        
        try performExtendedQueryOperation(
            operation: {
                let parseRequest = ParseRequest(statement: statement)
                try sendRequest(parseRequest)
                
                let flushRequest = FlushRequest()
                try sendRequest(flushRequest)
                
                try receiveResponse(type: ParseCompleteResponse.self)
            },
            onError: {
                // An error took place, but we don't know whether it occurred before or after the
                // Postgres server allocated resources for the statement.  Close the statement to
                // be safe.
                statement.close()
            }
        )
        
        return statement
    }
    
    /// Called by `Statement.execute(parameterValues:)` to execute a `Statement`.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Parameters:
    ///   - statement: the `Statement`
    ///   - parameterValues: the values of the statement's parameters
    /// - Returns: the `Cursor` containing the result
    /// - Throws: `PostgresError` is the operation fails
    internal func executeStatement(_ statement: Statement,
                                   parameterValues: [PostgresValueConvertible?] = []) throws -> Cursor {
        
        try performExtendedQueryOperation(
            operation: {
                try verifyStatementNotClosed(statement)
                
                let bindRequest = BindRequest(statement: statement, parameterValues: parameterValues)
                try sendRequest(bindRequest)
                
                let flushRequest = FlushRequest()
                try sendRequest(flushRequest)
                
                try receiveResponse(type: BindCompleteResponse.self)
                
                let executeRequest = ExecuteRequest(statement: statement)
                try sendRequest(executeRequest)
                
                try sendRequest(flushRequest)
            },
            onError: {
                // No cleanup required.  Since we always execute statements in the "unnamed portal"
                // any resources allocated by the Postgres server will be released at the end of the
                // current transaction or upon the next `BindRequest`, whichever comes first.
            }
        )
            
        let cursor = Cursor(statement: statement)
        
        // (The CursorState enum cases capture the Cursor id, rather than the Cursor instance, to
        // avoid a reference cycle.)
        cursorState = .open(cursorId: cursor.id, bufferedRow: nil)
        
        // Retrieve and buffer the first row of the cursor, if any.  We do this to check whether
        // the execution failed, so we can throw an error from this method.
        if let firstRow = try nextRowOfCursor(cursor) {
            cursorState = .open(cursorId: cursor.id, bufferedRow: firstRow)
        }
        
        return cursor
    }
    
    /// Called by `Statement.close()` to close a `Statement`.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// If an error occurs, it is logged but not thrown.
    ///
    /// - Parameter statement: the statement
    internal func closeStatement(_ statement: Statement) {
        
        if !statement.isClosed {
            do {
                try performExtendedQueryOperation(
                    operation: {
                        let closeStatementRequest = CloseStatementRequest(statement: statement)
                        try sendRequest(closeStatementRequest)
                        
                        let flushRequest = FlushRequest()
                        try sendRequest(flushRequest)
                        
                        try receiveResponse(type: CloseCompleteResponse.self)
                    }
                )
            } catch {
                log(.warning, "Error closing \(statement): \(error)")
            }
        }
    }
    
    /// Verifies the specified `Statement` is not closed.
    ///
    /// - Throws: `PostgresError.statementClosed` if closed
    private func verifyStatementNotClosed(_ statement: Statement) throws {
        if statement.isClosed {
            throw PostgresError.statementClosed
        }
    }
    
    /// Enumerates the cursor states of a `Connection`.
    ///
    /// Between when it is created and when it is closed, a connection can perform a sequence of
    /// SQL statements.  Each statement is performed by an exchange between PostgresClientKit and
    /// the Postgres server of "extended query" requests and responses.  For more information, see
    /// https://www.postgresql.org/docs/11/protocol-flow.html#PROTOCOL-FLOW-EXT-QUERY.
    ///
    /// A SQL statement can return a result consisting of a one or more rows.  Instead of exposing
    /// this result as an array of rows, PostgresClientKit exposes an iterator by which the next
    /// row can be obtained as needed.  This approach doesn't require materializing all rows in
    /// memory at once, and doesn't require retrieval of the last row from the Postgres server
    /// before returning the first row through the PostgresClientKit API.
    ///
    /// However, this approach makes `Connection` instances stateful, at least internally.  This
    /// enumeration identifies the possible states.  The `cursorState` property records the current
    /// state of this `Connection`.
    private enum CursorState {
        
        /// There is no currently open cursor.
        case closed
        
        /// There is a currently open cursor, with an optional buffered row.
        case open(cursorId: String, bufferedRow: Row?)
        
        /// There is a currently open cursor, but all rows have been retrieved.
        case drained(cursorId: String)
    }
    
    /// The current cursor state of this `Connection`.
    private var cursorState = CursorState.closed
    
    /// Called by the implementations of the public APIs that prepare a new `Statement`, bind
    /// parameter values to and execute a previously prepared `Statement`, and close a `Statement`.
    ///
    /// This method provides a consistent pattern for performing these operations.  It:
    ///
    ///     - Transitions this `Connection` to the `CursorState.closed` (if not already in that
    ///       state)
    ///     - Verifies other preconditions for performing the operation
    ///     - Executes the operation
    ///     - Upon an error in any of the previous steps, attempts to resynchronize this
    ///       `Connection` with the Postgres server then executes an optional error recovery closure
    ///
    /// - Parameters:
    ///   - operation: the operation to perform
    ///   - onError: an error recovery closure, executed if `operation` throws
    /// - Throws: `PostgresError` if the operation fails
    private func performExtendedQueryOperation(operation: () throws -> Void,
                                               onError: () -> Void = { }) throws {
        
        do {
            // If there is a currently open cursor, close it.  (If an unrecoverable error occurs,
            // this will close this connection.)
            closeCurrentlyOpenCursor()
            
            guard case .closed = cursorState else {
                preconditionFailure("cursorState not closed after closeCurrentlyOpenCursor()")
            }
            
            // Verify this connection is still open.
            try verifyConnectionNotClosed()
            
            // Perform the operation.
            try operation()
        } catch {
            // An error occurred, so try to resync this connection with the Postgres server.
            // If not successful, close this connection.
            resyncOrCloseConnection()
            
            // Perform the caller's error recovery closure (which should handle the case where
            // this connection is closed).
            onError()
            
            // And rethrow the original error.
            throw error
        }
    }
    

    //
    // MARK: Cursor processing
    //
    
    /// Returns the next row of the currently open cursor.
    ///
    /// - Parameter cursor: the `Cursor` instance for the currently open cursor, or `nil` if not
    ///     available
    /// - Returns: the next `Row`, or `nil` if there are no more rows in the cursor
    /// - Throws: `PostgresError` if the operation fails
    internal func nextRowOfCursor(_ cursor: Cursor? = nil) throws -> Row? {
        
        try verifyConnectionNotClosed()
        
        if let cursor = cursor {
            try verifyStatementNotClosed(cursor.statement)
            try verifyCursorNotClosed(cursor) // verifies that *this specific* cursor is open
        }
        
        var row: Row?
        
        switch cursorState {
            
        case .closed:
            throw PostgresError.cursorClosed // verifies that *some* cursor is open
            
        case .drained:
            row = nil
            
        case let .open(cursorId: cursorId, bufferedRow: bufferedRow):
            
            do {
                // Do we have a row buffered?
                if let bufferedRow = bufferedRow {
                    
                    // Yes, so return it.
                    row = bufferedRow
                    cursorState = .open(cursorId: cursorId, bufferedRow: nil)
                    
                } else {
                    
                    // No, so try to fetch a row from the Postgres server.
                    let response = try receiveResponse()
                    
                    switch response {
                        
                    case is EmptyQueryResponse: // the cursor has no rows
                        cursor?.rowCount = 0
                        cursorState = .drained(cursorId: cursorId)
                        
                    case let commandCompleteResponse as CommandCompleteResponse: // no more rows
                        let tokens = commandCompleteResponse.commandTag.split(separator: " ")
                        
                        switch tokens[0] {
                            
                        case "INSERT":
                            cursor?.rowCount = Int(tokens[2])
                            
                        case "DELETE", "UPDATE", "SELECT", "MOVE", "FETCH", "COPY":
                            cursor?.rowCount = Int(tokens[1])
                            
                        default:
                            break
                        }
                        
                        cursorState = .drained(cursorId: cursorId)

                    case let dataRowResponse as DataRowResponse:
                        row = Row(columns: dataRowResponse.columns)
                        
                    default:
                        throw PostgresError.serverError(
                            description: "unexpected response '\(response)'")
                    }
                }
                
                if case .drained = cursorState {
                    
                    // We just transitioned from .open to .drained.  Close the portal to release
                    // Postgres server resources.  Then perform a SyncRequest to close (commit or
                    // rollback) the current transaction (unless within a BEGIN/COMMIT block).
                    
                    let closePortalRequest = ClosePortalRequest()
                    try sendRequest(closePortalRequest)
                    
                    let flushRequest = FlushRequest()
                    try sendRequest(flushRequest)
                    
                    try receiveResponse(type: CloseCompleteResponse.self)
                    
                    let syncRequest = SyncRequest()
                    try sendRequest(syncRequest)
                    
                    try receiveResponse(type: ReadyForQueryResponse.self)
                }
            } catch {
                // An error occurred, so try to resync this connection with the Postgres server.
                // If not successful, close this connection.
                resyncOrCloseConnection()
                
                // And rethrow that error.
                throw error
            }
        }
        
        return row
    }
    
    /// Gets whether the specified `Cursor` is closed.
    ///
    /// - Parameter cursor: the `Cursor` to test
    /// - Returns: whether closed
    internal func isCursorClosed(_ cursor: Cursor) -> Bool {
        switch cursorState {
            
        case .closed:
            return true
            
        case let .open(cursorId: cursorId, bufferedRow: _):
            return cursorId != cursor.id
            
        case let .drained(cursorId: cursorId):
            return cursorId != cursor.id
        }
    }
    
    /// Closes the specified `Cursor`.
    ///
    /// - Parameter cursor: the `Cursor`
    internal func closeCursor(_ cursor: Cursor) {
        if !isCursorClosed(cursor) {
            closeCurrentlyOpenCursor()
        }
    }

    /// Closes any currently open `Cursor`.
    private func closeCurrentlyOpenCursor() {
        
        defer {
            cursorState = .closed // no matter what happens here
        }
        
        do {
            if !isClosed {
                if case .open = cursorState {
                    while try nextRowOfCursor() != nil { } // drain any remaining rows
                }
            }
        } catch {
            log(.warning, "Error closing cursor: \(error)")
        }
    }
    
    /// Verifies the specified `Cursor` is not closed.
    ///
    /// - Parameter cursor: the `Cursor`
    /// - Throws: `PostgresError.cursorClosed` if closed
    private func verifyCursorNotClosed(_ cursor: Cursor) throws {
        if isCursorClosed(cursor) {
            throw PostgresError.cursorClosed
        }
    }
    

    //
    // MARK: Convenience methods
    //
    
    /// Performs a SQL `BEGIN` command to explicitly initiate a transaction block.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Throws: `PostgresError` if the operation fails
    public func beginTransaction() throws {
        let statement = try prepareStatement(text: "BEGIN")
        defer { statement.close() }
        try statement.execute()
    }
    
    /// Performs a SQL `COMMIT` command to commit the current transaction.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Throws: `PostgresError` if the operation fails
    public func commitTransaction() throws {
        let statement = try prepareStatement(text: "COMMIT")
        defer { statement.close() }
        try statement.execute()
    }
    
    /// Performs a SQL `ROLLBACK` command to rollback the current transaction.
    ///
    /// Any previous `Cursor` for this `Connection` is closed.
    ///
    /// - Throws: `PostgresError` if the operation fails
    public func rollbackTransaction() throws {
        let statement = try prepareStatement(text: "ROLLBACK")
        defer { statement.close() }
        try statement.execute()
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
                
            case "1": response = try ParseCompleteResponse(responseBody: responseBody)
            case "2": response = try BindCompleteResponse(responseBody: responseBody)
            case "3": response = try CloseCompleteResponse(responseBody: responseBody)
            case "A": response = try NotificationResponse(responseBody: responseBody)
            case "C": response = try CommandCompleteResponse(responseBody: responseBody)
            case "D": response = try DataRowResponse(responseBody: responseBody)
            case "E": response = try ErrorResponse(responseBody: responseBody)
            case "I": response = try EmptyQueryResponse(responseBody: responseBody)
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
                break // don't need this, since we don't support CancelRequest
                
            case let errorResponse as ErrorResponse:
                throw PostgresError.sqlError(notice: errorResponse.notice)
                
            case let noticeResponse as NoticeResponse:
                delegate?.connection(self, didReceiveNotice: noticeResponse.notice)
                
            case let notificationResponse as NotificationResponse:
                delegate?.connection(
                    self,
                    didReceiveNotification: (processId: notificationResponse.processId,
                                             channel: notificationResponse.channel,
                                             payload: notificationResponse.payload))
                
            case let parameterStatusResponse as ParameterStatusResponse:
                
                delegate?.connection(
                    self,
                    didReceiveParameterStatus: (name: parameterStatusResponse.name,
                                                value: parameterStatusResponse.value))
                
                try Parameter.checkParameterStatusResponse(parameterStatusResponse)
                
            case is T:
                return response as! T
                
            default:
                throw PostgresError.serverError(
                    description: "unexpected response type '\(responseType)'")
            }
        }
    }
    
    /// The body of a response (everything after the bytes indicating the response length).
    internal class ResponseBody {
        
        /// Creates an `ResponseBody`.
        ///
        /// - Parameters:
        ///   - responseType: the response type
        ///   - responseLength: the response length, in bytes
        ///   - connection: the `Connection`
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
        @discardableResult internal func peekUInt8() throws -> UInt8 {
            
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
        
        /// Reads an unsigned big-endian 16-bit integer.
        ///
        /// - Returns: the value
        /// - Throws: `PostgresError` if the operation fails
        @discardableResult internal func readUInt16() throws -> UInt16 {
            
            let value = try
                UInt16(readUInt8()) << 8 +
                UInt16(readUInt8())
            
            return value
        }
        
        /// Reads an unsigned big-endian 32-bit integer.
        ///
        /// - Returns: the value
        /// - Throws: `PostgresError` if the operation fails
        @discardableResult internal func readUInt32() throws -> UInt32 {
            
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
        @discardableResult internal func readData(count: Int) throws -> Data {
            
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
        @discardableResult internal func readASCIICharacter() throws -> Character {
            
            let c = try Character(Unicode.Scalar(readUInt8()))
            
            return c
        }

        /// Reads a null-terminated UTF8 string.
        ///
        /// - Returns: the string
        /// - Throws: `PostgresError` if the operation fails
        @discardableResult internal func readUTF8String() throws -> String {
            
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
        
        /// Reads a UTF8 string.
        ///
        /// - Parameter byteCount: the length of the string, in bytes
        /// - Returns: the string
        /// - Throws: `PostgresError` if the operation fails
        @discardableResult internal func readUTF8String(byteCount: Int) throws -> String {
            
            let data = try readData(count: byteCount)
            
            guard let s = String(data: data, encoding: .utf8) else {
                throw PostgresError.serverError(description: "response contained invalid UTF8 string")
            }
            
            return s
        }
        
        /// Verifies the response body has been fully consumed.
        ///
        /// - Throws: `PostgresError.serverError` if not fully consumed
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
    
    /// A short string that identifies this `Connection`.
    public var description: String { return id }
}

// EOF
