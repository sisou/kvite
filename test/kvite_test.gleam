import gleam/option.{None, Some}
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
