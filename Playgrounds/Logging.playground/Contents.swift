import Foundation
import PostgresClientKit

let logger = Logger()
logger.level = .warning
logger.handler = ConsoleLogHandler()

let record = LogRecord(level: .warning,
                       message: "Watch out!",
                       context: "Session14",
                       timestamp: Date(),
                       file: #file,
                       function: #function,
                       line: #line)

logger.log(record) // the record is logged (because LogLevel.warning >= logger.level)

// Convenience methods make logging more concise.
logger.warning("Watch out!", context: "Session14")

// Examples of other log levels:
logger.severe("This is also logged") // because LogLevel.severe >= logger.level
logger.info("This is not logged")    // because LogLevel.info < logger.level

// EOF
