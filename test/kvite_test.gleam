import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit

import kvite

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn builder_test() {
  let assert Ok(kv) = kvite.default()

  assert kv |> kvite.get("hello") == Ok(None)
  assert kv |> kvite.set("hello", <<"world">>) == Ok(Nil)
  assert kv |> kvite.get("hello") == Ok(Some(<<"world">>))
  assert kv |> kvite.keys() == Ok(["hello"])
  assert kv |> kvite.del("hello") == Ok(Nil)
  assert kv |> kvite.get("hello") == Ok(None)
  assert kv |> kvite.keys() == Ok([])
}

pub fn keys_prefix_test() {
  let assert Ok(kv) = kvite.default()

  let assert Ok(_) = kv |> kvite.set("hello", <<"world">>)
  let assert Ok(_) = kv |> kvite.set("hella", <<"planet">>)
  let assert Ok(_) = kv |> kvite.set("hellu", <<"vaearth">>)
  let assert Ok(_) = kv |> kvite.set("helli", <<"copter">>)
  let assert Ok(_) = kv |> kvite.set("hero", <<"super">>)
  let assert Ok(_) = kv |> kvite.set("help", <<"me">>)

  assert kv |> kvite.keys()
    == Ok(
      ["hello", "hella", "hellu", "helli", "hero", "help"]
      |> list.sort(string.compare),
    )

  assert kv |> kvite.keys_prefix("hell")
    == Ok(["hello", "hella", "hellu", "helli"] |> list.sort(string.compare))
}
