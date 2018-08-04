defmodule RuleGenerator do
  def generate(genie, base_fact, 0, _width) do
    Genie.add_rule(genie, [provides: [base_fact]], fn _f ->
      %{base_fact => base_fact}
    end)
  end

  def generate(genie, base_fact, depth, width) do
    new_fact = :"#{UUID.uuid4()}"

    genie
    |> add_rules(base_fact, new_fact, width)
    |> generate(new_fact, depth - 1, width)
  end

  defp add_rules(genie, _base_fact, _new_fact, 0), do: genie

  defp add_rules(genie, base_fact, new_fact, width) do
    genie
    |> Genie.add_rule([provides: [base_fact], requires: [new_fact]], fn f ->
      %{base_fact => "#{f[new_fact]}#{width}"}
    end)
    |> add_rules(base_fact, new_fact, width - 1)
  end
end

inputs =
  [{4, 4}, {6, 6}, {2, 10}, {2, 20}]
  |> Enum.map(fn {d, w} ->
    {"#{d}x#{w}", Genie.init() |> RuleGenerator.generate(:result, d, w)}
  end)
  |> Map.new()

Benchee.run(
  %{
    "Solving" => fn genie -> Genie.solve_for(genie, :result) end
  },
  time: 15,
  warmup: 5,
  memory_time: 2,
  inputs: inputs
)
