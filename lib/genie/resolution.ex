defmodule Genie.Resolution do
  @moduledoc false

  alias Genie.Resolution

  defstruct facts: %{}

  def new do
    %Resolution{}
  end

  def take(resolution, facts) do
    values = Enum.map(facts, &Map.get(resolution.facts, &1))

    if Enum.any?(values, &is_nil/1) do
      :error
    else
      {:ok, facts |> Enum.zip(values) |> Map.new()}
    end
  end

  def into(facts, resolution) do
    Enum.reduce(facts, resolution, fn {fact, value}, resolution ->
      put_in(resolution.facts[fact], value)
    end)
  end
end
