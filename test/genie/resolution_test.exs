defmodule Genie.ResolutionTest do
  use ExUnit.Case, async: false

  alias Genie.Resolution

  setup do
    %{resolution: Resolution.new()}
  end

  test "allows inserting and retrieving facts", %{resolution: resolution} do
    assert [] = Resolution.take(resolution, [:fact_a])

    resolution = Resolution.into(%{fact_a: 1}, resolution)

    assert [%{fact_a: 1}] = Resolution.take(resolution, [:fact_a])

    resolution = Resolution.into(%{fact_a: 2}, resolution)

    assert [%{fact_a: 1}, %{fact_a: 2}] = Resolution.take(resolution, [:fact_a])

    resolution = Resolution.into(%{fact_a: 1}, resolution)

    assert [%{fact_a: 1}, %{fact_a: 2}] = Resolution.take(resolution, [:fact_a])
    assert [] = Resolution.take(resolution, [:fact_a, :fact_b])

    resolution = Resolution.into(%{fact_b: 1}, resolution)

    assert [%{fact_a: 1, fact_b: 1}, %{fact_a: 2, fact_b: 1}] =
             Resolution.take(resolution, [:fact_a, :fact_b])
  end
end
