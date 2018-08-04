defmodule Genie.Solver do
  @moduledoc false

  alias Genie.{
    Resolution,
    RuleStore
  }

  def solve(genie, facts, wanted) do
    facts
    |> Resolution.new()
    |> solve_for(wanted, genie.store)
    |> Resolution.take([wanted])
    |> Enum.map(&Map.fetch!(&1, wanted))
  end

  defp solve_for(%Resolution{} = resolution, wanted, store) do
    if Resolution.seen_fact?(resolution, wanted) do
      resolution
    else
      resolution = Resolution.mark_fact_as_seen(resolution, wanted)

      store
      |> RuleStore.lookup(:provides, wanted)
      |> Enum.reject(&Resolution.seen_rule?(resolution, &1))
      |> Enum.reduce(resolution, fn rule, resolution ->
        resolution
        |> solve_requirements(rule, store)
        |> run_rule(rule)
      end)
    end
  end

  defp solve_requirements(resolution, rule, store) do
    Enum.reduce(rule.requires, resolution, fn required_fact, resolution ->
      solve_for(resolution, required_fact, store)
    end)
  end

  defp run_rule(resolution, rule) do
    resolution
    |> Resolution.take(rule.requires)
    |> Enum.reduce(resolution, fn facts, resolution ->
      facts
      |> rule.fun.()
      |> Resolution.into(resolution)
    end)
    |> Resolution.mark_rule_as_seen(rule)
  end
end
