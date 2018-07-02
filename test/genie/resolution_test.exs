defmodule Genie.ResolutionTest do
  use ExUnit.Case, async: false

  alias Genie.Resolution

  setup do
    %{resolution: Resolution.new()}
  end

  test "allows inserting and retrieving facts", %{resolution: resolution} do
    assert :error = Resolution.take(resolution, [:fact_a])

    resolution = Resolution.into(%{fact_a: :value}, resolution)

    assert {:ok, %{fact_a: :value}} = Resolution.take(resolution, [:fact_a])
  end
end
