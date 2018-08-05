defmodule Genie do
  @moduledoc """
  Contains all the functions that are needed to interface with the libray.
  """

  alias Genie.RuleStore

  defstruct [:store]

  def init(opts \\ []) do
    store = Keyword.get(opts, :store, Genie.RuleStore.Map.new())

    %Genie{store: store}
  end

  defmacro add_rule(genie, do: block) do
    Genie.RuleParser.parse(genie, block, __CALLER__)
  end

  def add_rule(%Genie{} = genie, opts, fun) when is_function(fun, 1) do
    provides = Keyword.get(opts, :provides, [])
    requires = Keyword.get(opts, :requires, [])
    meta = opts |> Keyword.get(:meta, []) |> Enum.into(%{})

    rule = %Genie.Rule{
      id: UUID.uuid4(),
      fun: fun,
      provides: provides,
      requires: requires,
      meta: meta
    }

    %Genie{genie | store: Genie.RuleStore.insert(genie.store, rule)}
  end

  def solve_for(%Genie{} = genie, initial_facts \\ %{}, wanted) do
    Genie.Solver.solve(genie, initial_facts, wanted)
  end

  def list_rules(%Genie{} = genie) do
    RuleStore.list_rules(genie.store)
  end

  def list_facts(%Genie{} = genie, type) do
    RuleStore.list_facts(genie.store, type)
  end
end
