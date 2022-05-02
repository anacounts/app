defmodule AnacountApiTest do
  use ExUnit.Case
  doctest AnacountAPI

  test "greets the world" do
    assert AnacountAPI.hello() == :world
  end
end
