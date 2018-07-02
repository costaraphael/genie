defmodule Genie do
  @moduledoc """
  Contains all the functions that are needed to interface with the libray.
  """

  defstruct [:store]

  def init(store \\ Genie.RuleStore.Map.new()) do
    %Genie{store: store}
  end

  defmacro add_rule(genie, do: block) do
    Genie.RuleParser.parse(genie, block, __CALLER__)
  end

  def add_rule(%Genie{} = genie, opts, fun) when is_function(fun, 1) do
    provides = Keyword.get(opts, :provides, [])
    requires = Keyword.get(opts, :requires, [])

    rule = %Genie.Rule{id: UUID.uuid4(), fun: fun, provides: provides, requires: requires}

    %Genie{genie | store: Genie.RuleStore.insert(genie.store, rule)}
  end

  def solve_for(%Genie{} = genie, initial_facts \\ %{}, wanted) do
    Genie.Solver.solve(genie, initial_facts, wanted)
  end
end
