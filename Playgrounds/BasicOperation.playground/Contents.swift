import PostgresClientKit

do {
    var configuration = PostgresClientKit.ConnectionConfiguration()
    configuration.host = "127.0.0.1"
    configuration.ssl = true
    configuration.database = "example"
    configuration.user = "dbp"
    configuration.credential = .md5Password(password: "welcome1")
    
    let connection = try PostgresClientKit.Connection(configuration: configuration)
    
    defer {
        connection.close()
    }
    
    let statement = try connection.prepareStatement(
        text: "SELECT city, temp_lo, temp_hi, prcp, date FROM Weather WHERE city = $1;")
    
    defer {
        statement.close()
    }
    
    let cursor = try statement.execute(parameterValues: [ "San Francisco" ])
    
    for nextRow in cursor.rows {
        
        let row = try nextRow.get()
        let columns = row.columns
        
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
    print(error)
}

// EOF
