# Kvite - A simple KV store in SQLite

[![Package Version](https://img.shields.io/hexpm/v/kvite)](https://hex.pm/packages/kvite)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/kvite/)

Install Kvite like so:

```sh
gleam add kvite@1
```

## Usage

```gleam
import gleam/io
import gleam/option.{None, Some}
import kvite

pub fn main() {
  let assert Ok(kv) =
    kvite.new()
    // By default Kvite database are in-memory only.
    // If you need persistence, specify a path to the database file:
    |> kvite.with_path("kvite.db")
    |> kvite.open()

  // Now you can use `kv` to interact with the key-value store:

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
```

## Transactions

```gleam
// Start a transaction
kv |> kvite.begin_transaction()

// Make changes to the database
kv |> kvite.set("foo", <<"bar">>)

// You can also read during a transaction
kv |> kvite.get("foo") // -> Ok(Some(<<"bar">>))

// Then commit the transaction to apply it to the database
kv |> kvite.commit_transaction()
```

Further documentation can be found at <https://hexdocs.pm/kvite>.

## Development

```sh
gleam test  # Run the test(s)
```

## Trivia

The name "Kvite" comes from "KV" and "Lite" (because it's based on SQLite). I had a few ideas for some cooler names,
but my favourite of those package names was taken and in the end I decided to have a more _obvious_ name for simplicity.

If you want, you can pronounce it like the German word ["Quitte"](https://de.wikipedia.org/wiki/Quitte),
which is a fruit (and the phonetic spelling is actually `ˈkvɪtə`, so that's nice).
