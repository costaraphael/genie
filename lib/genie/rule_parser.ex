defmodule Genie.RuleParser do
  @moduledoc false

  def parse(genie, ast, caller) do
    ast = Macro.prewalk(ast, &Macro.expand(&1, caller))

    {ast, requires} = Macro.prewalk(ast, [], &find_requires/2)
    {ast, provides} = find_provides(ast)

    quote do
      opts = [requires: unquote(requires), provides: unquote(provides)]

      Genie.add_rule(unquote(genie), opts, fn var!(facts, Genie) ->
        unquote(ast)
      end)
    end
  end

  defp find_requires({{:., _, [{:facts, _, nil}, fact]}, _, _}, acc) do
    new_ast =
      quote do
        Map.fetch!(var!(facts, Genie), unquote(fact))
      end

    {new_ast, [fact | acc]}
  end

  defp find_requires({:facts, _, nil}, _acc) do
    raise CompileError, description: """
    Invalid usage of the `facts` variable. It should only be accessed to
    fetch facts that your rule depends on:

        facts.fact_a + facts.fact_b

    You should assign it directly to another variable or pass it to a
    function call.
    """
  end

  defp find_requires(ast, acc) do
    {ast, acc}
  end

  defp find_provides({:provide, _, [args]}) when is_list(args) do
    new_block =
      quote do
        %{unquote_splicing(args)}
      end

    provides = Enum.map(args, fn {k, _v} -> k end)

    {new_block, provides}
  end

  defp find_provides({:__block__, meta, inner}) do
    inner_block = List.last(inner)

    {new_inner_block, provides} = find_provides(inner_block)

    new_block = {:__block__, meta, List.replace_at(inner, -1, new_inner_block)}

    {new_block, provides}
  end

  defp find_provides({:case, meta, [condition, [do: clauses]]}) do
    {new_clauses, provides} = parse_arrow_clauses(clauses)

    new_case_ast = {:case, meta, [condition, [do: new_clauses]]}

    {new_case_ast, Enum.to_list(provides)}
  end

  defp find_provides({:cond, meta, [[do: clauses]]}) do
    {new_clauses, provides} = parse_arrow_clauses(clauses)

    new_cond_ast = {:cond, meta, [[do: new_clauses]]}

    {new_cond_ast, Enum.to_list(provides)}
  end

  defp find_provides(nil) do
    ast =
      quote do
        %{}
      end

    {ast, []}
  end

  defp find_provides(block) do
    raise CompileError, description: """
    Expected a call to `provide/1` at the end of the rule execution.

    Found: #{Macro.to_string(block)}
    """
  end

  defp parse_arrow_clauses(clauses) do
    Enum.map_reduce(clauses, MapSet.new(), fn {:->, meta, [pattern, block]}, provides ->
      {new_block, block_provides} = find_provides(block)

      {{:->, meta, [pattern, new_block]}, Enum.into(block_provides, provides)}
    end)
  end
end
