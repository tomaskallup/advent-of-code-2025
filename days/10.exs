inputContent =
  File.read!("./inputs/day-10.txt")
  |> String.trim()
  |> String.split("\n")

defmodule ILP do
  def solve(buttons, goal) do
    # vars = list of input vars (buttons)
    # map = map of output to list of input vars
    {vars, map} =
      buttons
      |> Enum.with_index()
      |> Enum.reduce({[], %{}}, fn {indexes, index}, {vars, map} ->
        var = "v#{index}"

        # Add button to each output in map
        new_map =
          Enum.reduce(indexes, map, fn key, map ->
            Map.update(map, key, [var], &[var | &1])
          end)

        {[var | vars], new_map}
      end)

    header = "Minimize\n  #{Enum.map_join(vars, " + ", fn var -> "1 #{var}" end)}"

    subject_to =
      "Subject To\n#{Enum.map_join(map, "\n", fn {output, inputs} -> "  o#{output}: #{Enum.map_join(inputs, " + ", fn var -> "1 #{var}" end)} = #{Enum.at(goal, output)}" end)}"

    bounds =
      "Bounds\n#{Enum.map_join(vars, "\n", fn var -> "  0 <= #{var}" end)}"

    general =
      "General\n#{Enum.map_join(vars, "\n", fn var -> "  #{var}" end)}"

    result = HiGHS.run_model(Enum.join([header, subject_to, bounds, general, "End"], "\n"))

    Enum.reduce(result.variables, 0, fn {_, val}, acc -> acc + val end)
  end
end

defmodule Machine do
  defimpl String.Chars, for: Machine do
    def to_string(machine) do
      lights = machine.lights |> Enum.map_join(fn l -> if(l == 1, do: "#", else: ".") end)

      target_lights =
        machine.target_lights |> Enum.map_join(fn l -> if(l == 1, do: "#", else: ".") end)

      buttons =
        machine.buttons |> Enum.map_join(" ", fn button -> "(#{Enum.join(button, ",")})" end)

      joltage = machine.joltage |> Enum.join(",")
      target_joltage = machine.target_joltage |> Enum.join(",")

      "[#{lights}] -> [#{target_lights}] #{buttons} {#{joltage}} -> {#{target_joltage}}"
    end
  end

  defstruct lights: [], buttons: [], joltage: [], target_joltage: [], target_lights: []

  def _parse_lights({splitter, machine}) do
    target_lights =
      Enum.at(splitter, 0)
      |> String.slice(1..-2//1)
      |> String.graphemes()
      |> Enum.map(fn ch -> if(ch == "#", do: 1, else: 0) end)

    lights = List.duplicate(0, length(target_lights))

    new_machine = Map.put(machine, :lights, lights) |> Map.put(:target_lights, target_lights)

    {Enum.drop(splitter, 1), new_machine}
  end

  def _parse_buttons({splitter, machine}) do
    buttons =
      Enum.take_while(splitter, fn <<first, _::binary>> -> first == ?( end)
      |> Enum.map(fn button ->
        button
        |> String.slice(1..-2//1)
        |> String.split(",")
        |> Enum.map(&String.to_integer/1)
      end)

    new_machine = Map.put(machine, :buttons, buttons)

    {Enum.drop(splitter, length(buttons)), new_machine}
  end

  def _parse_joltage({splitter, machine}) do
    target_joltage =
      Enum.at(splitter, -1)
      |> String.slice(1..-2//1)
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    joltage = List.duplicate(0, length(target_joltage))

    new_machine = Map.put(machine, :joltage, joltage) |> Map.put(:target_joltage, target_joltage)

    {Enum.drop(splitter, -1), new_machine}
  end

  def parse_machine(input) do
    machine = %Machine{}
    splitter = String.splitter(input, " ")

    _parse_lights({splitter, machine}) |> _parse_buttons() |> _parse_joltage() |> elem(1)
  end

  defp all_combinations([]), do: [[]]

  defp all_combinations([a | rest]) do
    sub = all_combinations(rest)

    sub ++ Enum.map(sub, &[a | &1])
  end

  def solve_lights(machine) do
    # Encode expected lights as integer
    expected =
      Enum.with_index(machine.target_lights)
      |> Enum.sum_by(fn {p, index} -> if(p == 1, do: 2 ** index, else: 0) end)

    # Encode buttons as integers
    encoded =
      machine.buttons
      |> Enum.map(&Enum.sum_by(&1, fn p -> 2 ** p end))

    # Generate all combinations of the buttons (sorted by length asc)
    combinations_sorted =
      encoded
      |> all_combinations()
      |> Enum.sort_by(&length/1)

    # Find a combination which matches after xor-ing all the buttons
    match =
      combinations_sorted
      |> Enum.find(fn seq ->
        result = Enum.reduce(seq, 0, &Bitwise.bxor/2)

        result == expected
      end)

    length(match)
  end

  def solve_joltage(%{buttons: buttons, target_joltage: target_joltage}) do
    ILP.solve(buttons, target_joltage)
  end
end

defmodule Main do
  def parse_machines(input) do
    Enum.map(input, &Machine.parse_machine/1)
  end

  def solve_lights(machines) do
    Enum.map(machines, &Machine.solve_lights/1) |> Enum.sum()
  end

  def solve_joltage(machines) do
    machines
    |> Enum.map(&Machine.solve_joltage/1)
    |> Enum.sum()
  end
end

machines = Main.parse_machines(inputContent)

IO.puts("Part 1: #{Main.solve_lights(machines)}")
IO.puts("Part 2: #{Main.solve_joltage(machines)}")
