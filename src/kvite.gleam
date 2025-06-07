import gleam/option.{type Option, None, Some}
import gleam/result

import sqlight

import kvite/raw

/// ### Usage:
///
/// ```gleam
/// import kvite
///
/// let kv = kvite.new()
///   // Optionally set the path to the SQLite database file.
///   // Default is `:memory:` for an in-memory database.
///   |> kvite.with_path("path/to/my_database.sqlite?cache=shared")
///   // Optionally set the name of the table to use.
///   // Default is "kv".
///   |> kvite.with_table("my_table")
///   |> kvite.open()
///```
pub opaque type KviteBuilder {
  KviteBuilder(path: String, table: String, conn: Option(sqlight.Connection))
}

/// Create a new KviteBuilder with default values: in-memory SQlite database and a table named "kv".
pub fn new() -> KviteBuilder {
  KviteBuilder(path: ":memory:", table: "kv", conn: None)
}

/// Set the path to the SQLite database file. Default is `:memory:` for an in-memory database.
pub fn with_path(builder: KviteBuilder, path path: String) -> KviteBuilder {
  KviteBuilder(..builder, path:)
}

/// Set the name of the table to use. Default is "kv".
///
/// Note: The table name must be a valid SQLite identifier and cannot contain special characters or spaces.
///
/// **WARNING:** Do not use unverified user-input for the table name, as the name is injected as-is into the SQL query.
pub fn with_table(
  builder: KviteBuilder,
  table_name table: String,
) -> KviteBuilder {
  KviteBuilder(..builder, table:)
}

/// Tell Kvite to use an existing connection. If not provided, a new connection will be created when `open` is called on the builder.
pub fn with_connection(
  builder: KviteBuilder,
  connection conn: sqlight.Connection,
) -> KviteBuilder {
  KviteBuilder(..builder, conn: Some(conn))
}

/// Open a Kvite database with the provided builder configuration.
pub fn open(builder: KviteBuilder) -> Result(Kvite, KviteError) {
  use conn <- result.try(case builder.conn {
    Some(conn) -> Ok(conn)
    None -> {
      use conn <- result.try(
        sqlight.open(builder.path)
        |> result.map_error(to_kvite_error),
      )

      // When we create the connection, we set some pragmas
      use _ <- result.try(
        raw.apply_pragmas(conn)
        |> result.map_error(to_kvite_error),
      )

      Ok(conn)
    }
  })

  // Create the table
  use _ <- result.try(
    raw.create_table(conn, builder.table)
    |> result.map_error(to_kvite_error),
  )

  Ok(Kvite(conn:, table: builder.table))
}

/// Create a new Kvite instance with default settings: in-memory database and "kv" table.
pub fn default() -> Result(Kvite, KviteError) {
  new() |> open()
}

/// Create a new Kvite instance with the builder, then use it like so:
///
/// ```gleam
/// import kvite
///
/// // If no custom config is required, this can be shortened to `kvite.default()`.
/// let kv = kvite.new() |> kvite.open()
///
/// // Now you can use `kv` to interact with the key-value store.
/// let assert Ok(_) = kv |> kvite.set("hello", <<"world">>)
/// let assert Ok(Some(<<"world">>)) = kv |> kvite.get("hello")
/// ```
pub opaque type Kvite {
  Kvite(conn: sqlight.Connection, table: String)
}

pub type KviteError {
  /// The error codes are documented here: [https://sqlite.org/rescode.html](https://sqlite.org/rescode.html)
  ///
  /// `sqlight` offers the [`sqlight.error_code_from_int`](https://hexdocs.pm/sqlight/sqlight.html#error_code_from_int)
  /// function to convert an integer code to a [`sqlight.ErrorCode`](https://hexdocs.pm/sqlight/sqlight.html#ErrorCode).
  SqlError(code: Int, message: String)
}

/// Get the value associated with a key. Returns `Ok(None)` if the key does not exist.
pub fn get(kv: Kvite, key key: String) -> Result(Option(BitArray), KviteError) {
  raw.get(kv.conn, kv.table, key)
  |> result.map_error(to_kvite_error)
}

/// Set the value for a key. If the key already exists, it will be replaced.
pub fn set(
  kv: Kvite,
  key key: String,
  value value: BitArray,
) -> Result(Nil, KviteError) {
  raw.set(kv.conn, kv.table, key, value)
  |> result.map_error(to_kvite_error)
}

/// Delete a key from the database.
pub fn del(kv: Kvite, key key: String) -> Result(Nil, KviteError) {
  raw.del(kv.conn, kv.table, key)
  |> result.map_error(to_kvite_error)
}

/// Get a list of all keys in the database. Returns an empty list if there are no keys.
pub fn keys(kv: Kvite) -> Result(List(String), KviteError) {
  raw.keys(kv.conn, kv.table)
  |> result.map_error(to_kvite_error)
}

/// Delete all keys and values from the Kvite instance. This operation is irreversible.
pub fn truncate(kv: Kvite) -> Result(Nil, KviteError) {
  raw.truncate(kv.conn, kv.table)
  |> result.map_error(to_kvite_error)
}

/// Begin a transaction. All operations after this will be part of the transaction and will only be applied to the
/// database when `commit_transaction` is called. Call `cancel_transaction` to discard the changes made during the transaction.
pub fn begin_transaction(kv: Kvite) -> Result(Nil, KviteError) {
  raw.begin_transaction(kv.conn)
  |> result.map_error(to_kvite_error)
}

/// Commit the current transaction. All changes made during the transaction will be applied.
pub fn commit_transaction(kv: Kvite) -> Result(Nil, KviteError) {
  raw.commit_transaction(kv.conn)
  |> result.map_error(to_kvite_error)
}

/// Cancel the current transaction. All changes made during the transaction will be discarded.
pub fn cancel_transaction(kv: Kvite) -> Result(Nil, KviteError) {
  raw.cancel_transaction(kv.conn)
  |> result.map_error(to_kvite_error)
}

pub fn sqlight_connection(kv: Kvite) -> sqlight.Connection {
  kv.conn
}

fn to_kvite_error(err: sqlight.Error) -> KviteError {
  SqlError(code: sqlight.error_code_to_int(err.code), message: err.message)
}
