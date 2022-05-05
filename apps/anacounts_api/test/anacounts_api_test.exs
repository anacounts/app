defmodule AnacountsApiTest do
  use ExUnit.Case
  doctest AnacountsAPI

  test "greets the world" do
    assert AnacountsAPI.hello() == :world
  end
end
