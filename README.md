# PostgresClientKit

PostgresClientKit provides a friendly Swift API for operating against a PostgreSQL database.

## Features

- **Doesn't require libpq.**  PostgresClientKit implements the Postgres network protocol in Swift, so it does not require `libpq`.

- **Developer-friendly API using modern Swift.**  For example, errors are represented by instances of `enum PostgresError: Error` and are raised by a `throw` or by returning a [`Result<Success, Error>`](https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md).

- **Safe conversion between Postgres and Swift types.** Type conversion is explicit and robust.  Conversion errors are signaled, not masked.  Additional Swift types for date/time values address the impedance mismatch between Postgres types and Foundation `Date`.

- **Memory efficient.** The rows in a result are exposed through an iterator, not an array.  Rows are lazily retrieved from the Postgres server.

- **SSL/TLS support.** Encrypts the connection between PostgresClientKit and the Postgres server.

- **Well-engineered**.  Complete API documentation, an extensive test suite, actively supported.

Sounds good?  Let's look at an example.

## Example

This is a basic, but complete, example of how to connect to Postgres, perform a SQL `SELECT` command, and process the resulting rows.  It uses the `weather` table in the [Postgres tutorial](https://www.postgresql.org/docs/11/tutorial-table.html).

```swift
import PostgresClientKit

do {
    var configuration = PostgresClientKit.ConnectionConfiguration()
    configuration.host = "127.0.0.1"
    configuration.ssl = true
    configuration.database = "example"
    configuration.user = "bob"
    configuration.credential = .md5Password(password: "welcome1")

    let connection = try PostgresClientKit.Connection(configuration: configuration)
    defer { connection.close() }

    let text = "SELECT city, temp_lo, temp_hi, prcp, date FROM weather WHERE city = $1;"
    let statement = try connection.prepareStatement(text: text)
    defer { statement.close() }

    let cursor = try statement.execute(parameterValues: [ "San Francisco" ])
    defer { cursor.close() }

    for row in cursor {
        let columns = try row.get().columns
        let city = try columns[0].string()
        let tempLo = try columns[1].int()
        let tempHi = try columns[2].int()
        let prcp = try columns[3].optionalDouble()
        let date = try columns[4].date()
    
        print("""
            \(city) on \(date): low: \(tempLo), high: \(tempHi), \
            precipitation: \(String(describing: prcp))
            """)
    }
} catch {
    print(error) // better error handling goes here
}
```

Output:

```
San Francisco on 1994-11-27: low: 46, high: 50, precipitation: Optional(0.25)
San Francisco on 1994-11-29: low: 43, high: 57, precipitation: Optional(0.0)
```

## Prerequisites

- **Swift 5 or later**  (PostgresClientKit uses Swift 5 language features)
- **`libssl-dev`** (only required on Linux, and only for SSL/TLS connections)

PostgresClientKit has been tested against Postgres versions 10 and 11.

## Building

```
cd <path-to-clone>
swift package clean
swift build
```

## Testing

[Set up a Postgres database for testing](Docs/setting_up_a_postgres_database_for_testing.md).  This is a one-time process.

Then:

```
cd <path-to-clone>
swift package clean
swift build
swift test
```

## Using

### Including in your project

#### Swift Package Manager

In your `Package.swift` file:

- Add PostgresClientKit to the `dependencies`.  For example:

[TODO: update URL and version number]

```swift
dependencies: [
    .package(url: "https://github.com/pitfield/PostgresClientKit", from: "0.0.0"),
],
```

- Reference the `PostgresClientKit` product in the `targets`.  For example:

```swift
targets: [
    .target(
        name: "MyProject",
        dependencies: ["PostgresClientKit"]),
]
```

#### CocoaPods

[TODO]

### Importing to your source code file

```swift
import PostgresClientKit
```

### Documentation

- [API documentation](Docs/API/index.html) [TODO: update with github.io URL]
- [Troubleshooting](Docs/troubleshooting.md)
- [FAQ](Docs/faq.md)

### Additional examples

- [PostgresClientKit-CommandLine-Example](https://github.com/pitfield/PostgresClientKit-CommandLine-Example): an example command-line application

- [PostgresClientKit-iOS-Example](https://github.com/pitfield/PostgresClientKit-iOS-Example): an example iOS app

## Contributing

Thank you for your interest in contributing to PostgresClientKit.

This project has a code of conduct.  See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

Please use [issues](../../issues) to:

- ask questions
- report problems (bugs)
- request enhancements

Pull requests are welcomed.  For a non-trivial contribution (for example, more than correcting spelling, typos, or whitespace) please first discuss the proposed change by opening an issue.
    
## License

PostgresClientKit is licensed under the Apache 2.0 license.  See [LICENSE](LICENSE) for details.

## Versioning

PostgresClientKit uses [Semantic Versioning 2.0.0](https://semver.org).  For the versions available, see the [tags on this repository](../../tags).

## Built with

- [Kitura BlueSocket](https://github.com/IBM-Swift/BlueSocket) - socket library
- [Kitura BlueSSLService](https://github.com/IBM-Swift/BlueSSLService) - SSL/TLS support
- [Jazzy](https://github.com/realm/jazzy) - generation of API documentation pages

## Authors

- David Pitfield [(@pitfield)](https://github.com/pitfield)
