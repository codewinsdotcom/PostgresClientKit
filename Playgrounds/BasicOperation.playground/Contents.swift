import Postgres

func performQuery() throws {
    
    var configuration = Postgres.ConnectionConfiguration()
    configuration.user = "dbp"
    configuration.credential = .md5Password(password: "foo")
    
    let connection = try Postgres.Connection(configuration: configuration)
    
    let statement = try connection.prepareStatement(
        text: "SELECT * FROM project WHERE airport = $1;")
    
    defer {
        statement.close()
        connection.close()
    }
    
    let result = try statement.execute(parameterValues: [ "RDM" ])
    
    for nextRow in result.rows {
        
        let row = try nextRow()
        let columns = row.columns
        
        let name = try columns[0].string()
        let airport = try columns[1].string()
        let completed = try columns[2].date()
        
        print("\(name) \(airport) \(completed)")
    }
}

// EOF
