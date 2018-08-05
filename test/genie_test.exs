defmodule GenieTest do
  use ExUnit.Case

  require Genie

  test "solves simple problems" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(result: facts.a + facts.b)
      end
      |> Genie.add_rule do
        provide(a: 2)
      end
      |> Genie.add_rule do
        provide(b: 4)
      end

    assert [6] = Genie.solve_for(genie, :result)
  end

  test "rules are only run once per fact combination" do
    parent = self()

    Genie.init()
    |> Genie.add_rule do
      send(parent, {:rule, :a1})
      provide(a: 1)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :a2})
      provide(a: 2)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :b1})
      provide(b: 2)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :b2})
      provide(b: 5)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :ab})
      provide(a: 3, b: 4)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :c})
      provide(c: facts.a + facts.b)
    end
    |> Genie.add_rule do
      send(parent, {:rule, :d})
      provide(d: facts.a * facts.b)
    end
    |> Genie.add_rule do
      provide(result: facts.c + facts.d)
    end
    |> Genie.solve_for(:result)

    assert collect_received_rules() == ~w[a1 a2 ab b1 b2 c c c c c c c c c d d d d d d d d d]a
  end

  test "allows adding metadata to rules" do
    genie =
      Genie.init()
      |> Genie.add_rule([provides: [:a], meta: [description: "Rule A"]], fn _f ->
        %{a: 1}
      end)
      |> Genie.add_rule do
        meta(description: "Rule B")

        provide(b: 2)
      end

    descriptions =
      genie
      |> Genie.list_rules()
      |> Enum.map(& &1.meta.description)
      |> Enum.sort()

    assert descriptions == ["Rule A", "Rule B"]
  end

  test "allows listing all the provided facts" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(a: 1)
      end
      |> Genie.add_rule do
        provide(b: 2)
      end

    assert [:a, :b] = Genie.list_facts(genie, :provides)
    assert [] = Genie.list_facts(genie, :requires)
  end

  test "wikipedia example" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(is_green: facts.is_frog)
      end
      |> Genie.add_rule do
        provide(is_frog: facts.croaks and facts.eats_flies)
      end

    assert [true] = Genie.solve_for(genie, %{croaks: true, eats_flies: true}, :is_green)
  end

  test "solves problems with multiple solutions" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(result: facts.a + facts.b)
      end
      |> Genie.add_rule do
        provide(a: 2)
      end
      |> Genie.add_rule do
        provide(b: 2)
      end
      |> Genie.add_rule do
        provide(b: 3)
      end
      |> Genie.add_rule do
        provide(b: facts.a + 1)
      end

    assert [4, 5] = Genie.solve_for(genie, :result)

    assert [3, 4, 5] = Genie.solve_for(genie, %{b: 1}, :result)
  end

  test "deals with circular dependency" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(result: facts.a + facts.b)
      end
      |> Genie.add_rule do
        provide(a: facts.b + 2)
      end
      |> Genie.add_rule do
        b = facts.a + 1
        provide(b: b)
      end

    assert [] = Genie.solve_for(genie, :result)
  end

  test "allows case/cond/if in rules when using macro form" do
    genie =
      Genie.init()
      |> Genie.add_rule do
        provide(result: facts.a + facts.b + facts.c)
      end
      |> Genie.add_rule do
        if facts.c < 5 do
          provide(a: 2)
        end
      end
      |> Genie.add_rule do
        case facts.a do
          x when x < 5 -> provide(b: facts.c + 1)
          _ -> provide(b: 5)
        end
      end
      |> Genie.add_rule do
        cond do
          facts.arg > 5 -> provide(c: 3)
          facts.arg > 0 -> provide(c: 2)
          true -> provide(c: 1)
        end
      end

    assert [7] = Genie.solve_for(genie, %{arg: 2}, :result)
  end

  @tag capture_log: true
  test "disallows using the facts variable in any other way" do
    assert_raise CompileError, ~r/Invalid usage/, fn ->
      Code.compile_string("""
      require Genie

      Genie.add_rule Genie.init() do
        IO.inspect(facts)

        provide([])
      end
      """)
    end

    assert_raise CompileError, ~r/Invalid usage/, fn ->
      Code.compile_string("""
      require Genie

      Genie.add_rule Genie.init() do
        other = facts

        provide([])
      end
      """)
    end
  end

  test "raises if you don't end the execution with a call to provide/1" do
    assert_raise CompileError, ~r/call to `provide\/1`/, fn ->
      quote do
        require Genie

        Genie.add_rule Genie.init() do
          true
        end
      end
      |> Code.compile_quoted()
    end
  end

  test "raises if you try to add a rule that does nothing" do
    assert_raise ArgumentError, ~r/rule without providing facts/, fn ->
      Genie.add_rule Genie.init() do
        provide([])
      end
    end
  end

  defp collect_received_rules(rules \\ []) do
    receive do
      {:rule, rule} -> collect_received_rules([rule | rules])
    after
      0 ->
        Enum.sort(rules)
    end
  end
end
