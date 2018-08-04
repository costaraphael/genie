defmodule Genie.Resolution do
  @moduledoc false

  alias Genie.{
    Resolution,
    Rule
  }

  defstruct facts: %{}, seen: MapSet.new()

  def new(initial_facts \\ %{}) do
    into(initial_facts, %Resolution{})
  end

  def into(%{} = facts, %Resolution{} = resolution) do
    Enum.reduce(facts, resolution, fn {fact, value}, resolution ->
      update_in(
        resolution,
        [Access.key!(:facts), Access.key(fact, MapSet.new())],
        &MapSet.put(&1, value)
      )
    end)
  end

  def take(%Resolution{} = resolution, wanted_facts) when is_list(wanted_facts) do
    Enum.reduce(wanted_facts, [%{}], fn fact, fact_maps ->
      for fact_map <- fact_maps,
          value <- Map.get(resolution.facts, fact, []),
          do: Map.put(fact_map, fact, value)
    end)
  end

  def seen_fact?(%Resolution{} = resolution, fact) do
    fact in resolution.seen
  end

  def mark_fact_as_seen(%Resolution{} = resolution, fact) do
    %Resolution{resolution | seen: MapSet.put(resolution.seen, fact)}
  end

  def seen_rule?(%Resolution{} = resolution, %Rule{} = rule) do
    rule.id in resolution.seen
  end

  def mark_rule_as_seen(%Resolution{} = resolution, %Rule{} = rule) do
    %Resolution{resolution | seen: MapSet.put(resolution.seen, rule.id)}
  end
end
