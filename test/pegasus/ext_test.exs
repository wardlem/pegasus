defmodule ExampleExt1 do
  use Pegasus.Ext
end

defmodule ExampleExt2 do
  use Pegasus.Ext

  def name, do: "TheName"
end

defmodule Pegasus.ExtTest do
  use ExUnit.Case
  doctest Pegasus.Ext

  test "it provides a default :name function" do
    assert ExampleExt1.name() == "ExampleExt1"
  end

  test "the default :name function is overridable" do
    assert ExampleExt2.name() == "TheName"
  end
end
