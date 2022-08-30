import PostgresClientKit

struct Weather: Decodable {
    let city: String
    let lowestTemperature: Int
    let highestTemperature: Int
    let precipitation: Double?
    let date: PostgresDate
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

    // Notice that the columns must be in the same order as the Weather
    // properties, but may have different names.
    let text = "SELECT city, temp_lo, temp_hi, prcp, date FROM weather;"
    let statement = try connection.prepareStatement(text: text)
    defer { statement.close() }
    
    let cursor = try statement.execute()
    defer { cursor.close() }
    
    for row in cursor {
        let weather = try row.get().decodeByColumnIndex(Weather.self)
        print(weather)
    }
} catch {
    print(error) // better error handling goes here
}

// EOF
