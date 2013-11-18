Code.require_file "test_helper.exs", __DIR__

defmodule CharTest do
  use ExUnit.Case, async: true

  doctest Char

  test :category do
    assert Char.category(?A)           == { :letter, :uppercase }
    assert Char.category(?é)           == { :letter, :lowercase }
    assert Char.category("é")          == { :letter, :lowercase }
    assert Char.category(" ")          == { :separator, :space }
    assert Char.category("ab")         == { :letter, :lowercase }
    assert Char.category(-1)           == nil
    assert Char.category("")           == nil
    # Non-UTF8 input. The function doesn't work for that.
    assert_raise(FunctionClauseError, fn -> Char.category(<<255, 255>>) end)
  end
end
