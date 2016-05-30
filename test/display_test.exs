defmodule DisplayTest do
  use ExUnit.Case, async: true

  test "stores the number displayed" do
    {:ok, display} = Display.start_link
    Display.put(display, :number, 13)
    assert Display.get(display, :number) == 13
  end
end

