# FAQ

### Does PostgresClientKit provide connection pooling?

Yes.  See the [API documentation](https://codewinsdotcom.github.io/PostgresClientKit/Docs/API/index.html) for `ConnectionPool`.

### Is the PostgresClientKit API synchronous or asynchronous?

`ConnectionPool` provides an **asynchronous** API to service a large number of requests using a small number of shared `Connection` instances and threads.  This is useful for server-side Swift.

`Connection` (together with `Statement` and `Cursor`) provide a **synchronous** API for performing a SQL statement.  This makes it easy to sequence the steps in preparing and executing a SQL statement, processing the rows it returns, and handling any errors on the way.

Concurrency is [an evolving area](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782) in Swift.  It will be interesting to see what ideas gain traction.

### Why can't I reference a column in a `Row` by name, instead of by index?

Postgres doesn't require the columns returned by a `SELECT` to be uniquely named (for example, in queries with joins or computed columns).  Name-based access is better left to a higher level, such as an object-relational mapper.

That said, as of v1.5.0, PostgresClientKit can decode a row into a Swift type that conforms to the `Decodable` protocol, mapping columns to stored properties by either by or by position.  See the [API documentation](https://codewinsdotcom.github.io/PostgresClientKit/Docs/API/index.html) for `Row.decodeByColumnName(_:defaultTimeZone)` and `Row.decodeByColumnIndex(_:defaultTimeZone)`.

### In retrieving the value of a column, why do I need to specify the Swift type?

To make Postgres-to-Swift type conversion explicit and robust, PostgresClientKit defers to the developer.  Should a SQL `NUMERIC` map to a Swift `Int`, `Double`, or `Decimal`?  Should a SQL `VARCHAR` map to a Swift `String` or an `Optional<String>`?  Answering these questions requires domain knowledge, which may not be encoded in the SQL data model, but which the developer (hopefully) has.
