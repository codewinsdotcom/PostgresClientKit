import PostgresClientKit

struct Weather: Decodable {
    let date: PostgresDate
    let city: String
    let temp_lo: Int
    let temp_hi: Int
    let prcp: Double?
}

do {
    var configuration = PostgresClientKit.ConnectionConfiguration()
    configuration.host = "127.0.0.1"
    configuration.ssl = true
    configuration.database = "example"
    configuration.user = "bob"
    configuration.credential = .scramSHA256(password: "welcome1")
    
    let connection = try PostgresClientKit.Connection(configuration: configuration)
    defer { connection.close() }

    // Note that the columns must have the same names as the Weather
    // properties, but may be in a different order.
    let text = "SELECT city, temp_lo, temp_hi, prcp, date FROM weather;"
    let statement = try connection.prepareStatement(text: text)
    defer { statement.close() }
    
    let cursor = try statement.execute(retrieveColumnMetadata: true)
    defer { cursor.close() }
    
    for row in cursor {
        let weather = try row.get().decodeByColumnName(Weather.self)
        print(weather)
    }
} catch {
    print(error) // better error handling goes here
}

// EOF
