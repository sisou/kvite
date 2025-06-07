//// ## Here be dragons!
////
//// This modules contains functions for raw operations on a `sqlight.Connection` used by Kvite.
//// The table must follow the Kvite schema of having a `key TEXT` and a `value BLOB` column.
////
//// These functions are used internally by Kvite and are not intended for direct use by applications.
//// Only use them as an escape hatch when you know what you're doing.

import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import gleam/result

import sqlight

pub fn apply_pragmas(
  connection conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  use _ <- result.try(
    "PRAGMA main.synchronous = NORMAL;"
    |> sqlight.exec(conn),
  )
  use _ <- result.try(
    "PRAGMA main.journal_mode = WAL2;"
    |> sqlight.exec(conn),
  )
  use _ <- result.try(
    "PRAGMA main.auto_vacuum = INCREMENTAL;"
    |> sqlight.exec(conn),
  )
  Ok(Nil)
}

pub fn create_table(
  connection conn: sqlight.Connection,
  table_name table: String,
) -> Result(Nil, sqlight.Error) {
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> table
    <> " (key TEXT PRIMARY KEY, value BLOB);"

  sql
  |> sqlight.exec(conn)
}

pub fn get(
  connection conn: sqlight.Connection,
  table_name table: String,
  key key: String,
) -> Result(Option(BitArray), sqlight.Error) {
  use rows <- result.try(
    { "SELECT value FROM " <> table <> " WHERE key = ?;" }
    |> sqlight.query(conn, [sqlight.text(key)], {
      use value <- decode.field(0, decode.bit_array)
      decode.success(value)
    }),
  )

  case rows {
    // Not found
    [] -> Ok(None)
    // Found one value
    [value] -> Ok(Some(value))
    _ -> panic as "Too many rows returned"
  }
}

pub fn set(
  connection conn: sqlight.Connection,
  table_name table: String,
  key key: String,
  value value: BitArray,
) -> Result(Nil, sqlight.Error) {
  use _res <- result.try(
    { "INSERT OR REPLACE INTO " <> table <> " (key, value) VALUES (?, ?);" }
    |> sqlight.query(conn, [sqlight.text(key), sqlight.blob(value)], decode.int),
  )
  Ok(Nil)
}

pub fn del(
  connection conn: sqlight.Connection,
  table_name table: String,
  key key: String,
) -> Result(Nil, sqlight.Error) {
  use _res <- result.try(
    { "DELETE FROM " <> table <> " WHERE key = ?;" }
    |> sqlight.query(conn, [sqlight.text(key)], decode.int),
  )
  Ok(Nil)
}

pub fn keys(
  connection conn: sqlight.Connection,
  table_name table: String,
) -> Result(List(String), sqlight.Error) {
  { "SELECT key FROM " <> table <> ";" }
  |> sqlight.query(conn, [], {
    use key <- decode.field(0, decode.string)
    decode.success(key)
  })
}

pub fn truncate(
  connection conn: sqlight.Connection,
  table_name table: String,
) -> Result(Nil, sqlight.Error) {
  { "DELETE FROM " <> table <> ";" }
  |> sqlight.exec(conn)
}

pub fn begin_transaction(
  connection conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  "BEGIN TRANSACTION;"
  |> sqlight.exec(conn)
}

pub fn commit_transaction(
  connection conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  "COMMIT TRANSACTION;"
  |> sqlight.exec(conn)
}

pub fn cancel_transaction(
  connection conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  "ROLLBACK TRANSACTION;"
  |> sqlight.exec(conn)
}
