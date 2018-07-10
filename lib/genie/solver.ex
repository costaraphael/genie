defmodule Genie.Solver do
  @moduledoc false

  alias Genie.{
    Resolution,
    RuleStore
  }

  def solve(genie, facts, wanted) do
    facts
    |> Resolution.into(Resolution.new())
    |> solve_for(wanted, MapSet.new(), genie.store)
    |> Enum.map(fn resolution ->
      {:ok, %{^wanted => fact}} = Resolution.take(resolution, [wanted])

      fact
    end)
  end

  defp solve_for(resolution, wanted, seen, store) do
    if wanted in seen do
      []
    else
      seen = MapSet.put(seen, wanted)

      case Resolution.take(resolution, [wanted]) do
        {:ok, _} ->
          [resolution]

        :error ->
          for rule <- RuleStore.lookup(store, :provides, wanted),
              resolution <- solve_requirements(rule, resolution, seen, store),
              resolution <- run_rule(rule, resolution),
              do: resolution
      end
    end
  end

  defp solve_requirements(rule, resolution, seen, store) do
    Enum.reduce(rule.requires, [resolution], fn required_fact, resolutions ->
      for resolution <- resolutions,
          resolution <- solve_for(resolution, required_fact, seen, store),
          match?({:ok, _}, Resolution.take(resolution, [required_fact])),
          do: resolution
    end)
  end

  defp run_rule(rule, resolution) do
    {:ok, facts} = Resolution.take(resolution, rule.requires)

    resolution =
      facts
      |> rule.fun.()
      |> Resolution.into(resolution)

    case Resolution.take(resolution, rule.provides) do
      {:ok, _} -> [resolution]
      :error -> []
    end
  end
end
