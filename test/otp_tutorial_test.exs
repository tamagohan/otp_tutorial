defmodule OtpTutorialTest do
  use ExUnit.Case
  doctest OtpTutorial

  test "greets the world" do
    assert OtpTutorial.hello() == :world
  end
end
