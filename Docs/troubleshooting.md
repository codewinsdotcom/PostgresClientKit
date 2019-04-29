# Troubleshooting

## Enabling PostgresClientKit logging

PostgresClientKit logs internal events of interest.  To change the log verbosity, set the log level of the `Postgres.logger` in your Swift code.  For example:

```
Postgres.logger.level = .all
```

By default, the log is written to `stdout`.  Change this by setting the log handler of the `Postgres.logger`.  For details, see the API documentation for the `LogHandler` protocol.


## Receiving log messages from the Postgres server

In troubleshooting, it can also be useful for your Swift application to receive log messages from the Postgres server.  Enable this by setting the Postgres configuration parameter named [`client_min_messages`](https://www.postgresql.org/docs/11/runtime-config-client.html#GUC-CLIENT-MIN-MESSAGES) (for example, in the [`postgresql.conf`](https://www.postgresql.org/docs/11/config-setting.html#CONFIG-SETTING-CONFIGURATION-FILE) file for your Postgres server).  For example:

```
client_min_messages = debug5
```

Then, do one or both of the following:

- Increase the `Postgres.logger` level to `.finer` or higher, as described above.  The log messages received from the Postgres server will be logged by PostgresClientKit.

- Create a class that conforms to the `ConnectionDelegate` protocol and implements the `connection(_:didReceiveNotice:)` method.  Set the `delegate` property of the `Connection` to an instance of this class.  (Note that `delegate` is a `weak` property of `Connection`, so your code must also hold its own reference to the delegate.)


## Errors in creating a connection

Confirm you can connect using [`psql`](https://www.postgresql.org/docs/11/app-psql.html), explicitly specifying the host, port, database, and username.  For example:

```
psql --host 127.0.0.1 --port 5432 --dbname example --username bob
```


## Can't create an SSL/TLS connection

In the [`postgresql.conf`](https://www.postgresql.org/docs/11/config-setting.html#CONFIG-SETTING-CONFIGURATION-FILE) file for your Postgres server, confirm that:

```
ssl = on
```


## Authentication issues

Review the [`pg_hba.conf`](https://www.postgresql.org/docs/11/auth-pg-hba-conf.html) file for your Postgres server.  PostgresClientKit supports the `trust`, `password`, and `md5` options for `auth-method`.


## Cursor is unexpectedly closed

The deinitializers of `Connection`, `Statement`, and `Cursor` call `close()` on instances of those types.  This is normally a convenient way to ensure Postgres resources are released, but can have unexpected side effects, particular for `Statement`.  For example:

```swift
// Perform a first SQL command.
var statement = try connection.prepareStatement(text: ...)
var cursor = try statement.execute()
...

// Perform a second SQL command, re-using the same variables.
statement = try connection.prepareStatement(text: ...)  // closes first cursor
cursor = try statement.execute()                        // triggers deinit of first cursor & statement
assert(!cursor.isClosed)                                // fails!
...
```

In this code fragment, the second assignment to the `cursor` variable releases the only reference to the first `Cursor` instance, allowing it to be deinitialized and then deallocated.  This, in turn, releases the only reference to the first `Statement` instance, and it too is deinitialized and deallocated.  The deinitializer for `Statement` calls `close()` which, as a side effect, closes any open cursor for the connection, in this case the just-created second `Cursor` instance.  Doh!

You can prevent this in several ways:

- Explicitly `close()` the first `Statement` before preparing the second.

- Assign the second `Statement` instance to a different variable than the first.

- Perform the each SQL command within its own `do { }` block, so that the first `Statement` is deinitialized and deallocated before starting the second SQL command.

