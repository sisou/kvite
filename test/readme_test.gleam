import gleam/io
import gleam/option.{None, Some}
import kvite

pub fn main_test() {
  let assert Ok(kv) =
    kvite.new()
    // By default Kvite database are in-memory only.
    // If you need persistence, specify a path to the database file:
    |> kvite.with_path("kvite.db")
    // Use memory for the test, though
    |> kvite.with_path(":memory:")
    |> kvite.open()

  // Now you can use `kv` to interact with the key-value store.

  // Set a value
  let assert Ok(_) = kv |> kvite.set("hello", <<"world">>)

  // Read a value
  case kv |> kvite.get("hello") {
    Ok(Some(value)) -> {
      // Found a value
      assert value == <<"world">>
    }
    Ok(None) -> {
      // Key not found
      io.println("Uh oh...")
    }
    Error(kvite.SqlError(_code, message)) -> {
      // SQL or connection error, see `code` and `message` for details
      io.println_error(message)
    }
  }
}
