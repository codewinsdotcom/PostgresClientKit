# FAQ

### Why is the PostgresClientKit API synchronous/blocking?

A design goal of PostgresClientKit is support for multiple application types.  It can be used for server-side Swift, command-line tools, macOS apps, and iOS apps.  It also does not constrain the other frameworks and design patterns used by the application.  Consequently, PostgresClientKit defers to the consuming application the decision of whether database operations should be performed asynchronously and, if so, how that is done.

Additionally, the PostgresClientKit API methods are fine grained.  For example, performing a SQL `SELECT` involves calling:

- `Connection.prepareStatement(text:)`
- `Statement.execute(parameterValues:)`
- `Cursor.next()` once for each row in the result
- `Cursor.close()`
- `Statement.close()`

Instead of sequentially performing separate asynchronous operations for each of these steps, an application would often compose the entire sequence into a single asynchronous operation.  Consequently, there is little value in PostgresClientKit providing the ability to asynchronously execute individual steps.

### Does PostgresClientKit provide connection pooling?

No, but it's [on the roadmap](https://github.com/codewinsdotcom/PostgresClientKit/issues/1).

### Why can't I reference a column in a `Row` by name, instead of by index?

Postgres doesn't require the columns returned by a `SELECT` to be uniquely named (for example, in queries with joins or computed columns).  Name-based access is better left to a higher level, such as an object-relational mapper.

### In retrieving the value of a column, why do I need to specify the Swift type?

To make Postgres-to-Swift type conversion explicit and robust, PostgresClientKit defers to the developer.  Should a SQL `NUMERIC` map to a Swift `Int`, `Double`, or `Decimal`?  Should a SQL `VARCHAR` map to a Swift `String` or an `Optional<String>`?  Ultimately answering these questions requires domain knowledge, which may not be encoded in the SQL data model, but which (hopefully) the developer has.
