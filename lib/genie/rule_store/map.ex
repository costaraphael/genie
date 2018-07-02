defmodule Genie.RuleStore.Map do
  @moduledoc false

  defstruct provides: %{}, requires: %{}, rules: %{}

  def new do
    %__MODULE__{}
  end

  defimpl Genie.RuleStore do
    def insert(store, rule) do
      if match?({[], []}, {rule.provides, rule.requires}) do
        raise ArgumentError, message: "You cannot add a rule without providing facts."
      end

      store
      |> Map.update!(:rules, &Map.put(&1, rule.id, rule))
      |> update_fact_list(rule.id, :provides, rule.provides)
      |> update_fact_list(rule.id, :requires, rule.requires)
    end

    def lookup(store, type, fact) do
      store
      |> Map.get(type)
      |> Map.get(fact, [])
      |> Enum.map(&Map.fetch!(store.rules, &1))
    end

    defp update_fact_list(store, rule, type, fact_list) do
      Enum.reduce(fact_list, store, fn fact, store ->
        Map.update!(store, type, fn facts ->
          Map.update(facts, fact, [rule], &[rule | &1])
        end)
      end)
    end
  end
end
