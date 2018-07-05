defmodule Genie.Resolution do
  @moduledoc false

  alias Genie.Resolution

  defstruct facts: %{}

  def new do
    %Resolution{}
  end

  def take(resolution, wanted_facts) do
    with {:ok, values} <- take_values(resolution.facts, wanted_facts, []) do
      {:ok, wanted_facts |> Enum.zip(values) |> Map.new()}
    end
  end

  def into(facts, resolution) do
    Enum.reduce(facts, resolution, fn {fact, value}, resolution ->
      put_in(resolution.facts[fact], value)
    end)
  end

  defp take_values(_facts, [], values), do: {:ok, Enum.reverse(values)}
  defp take_values(facts, [head | tail], values) do
    with {:ok, value} <- Map.fetch(facts, head) do
      take_values(facts, tail, [value | values])
    end
  end
end
