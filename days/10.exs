inputContent =
  File.read!("./inputs/day-10.txt")
  |> String.trim()
  |> String.split("\n")

defimpl String.Chars, for: Map do
  def to_string(map) do
    interior =
      map
      |> Enum.map_join(", ", fn {k, v} -> "#{k} => #{v}" end)

    "%{#{interior}}"
  end
end

defimpl String.Chars, for: Tuple do
  def to_string(tuple) do
    interior =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&Kernel.to_string/1)
      |> Enum.join(", ")

    "{#{interior}}"
  end
end

defmodule GF2 do
  import Bitwise

  def solve(a, b) do
    augmented = augment(a, b)
    {rref, pivots} = eliminate(augmented)
    find_min_solution(rref, pivots)
  end

  # Create augment matrix
  defp augment(a, b) do
    Enum.zip(a, b)
    |> Enum.map(fn {row, bi} -> row ++ [bi] end)
  end

  defp xor_rows(row1, row2) do
    Enum.zip(row1, row2)
    |> Enum.map(fn {x, y} -> bxor(x, y) end)
  end

  defp eliminate(matrix) do
    cols = length(hd(matrix)) - 1

    Enum.reduce(0..(cols - 1), {matrix, 0, []}, fn col, {mat, row, pivots} ->
      case find_pivot(mat, row, col) do
        nil ->
          {mat, row, pivots}

        pivot_row ->
          mat =
            mat
            |> swap_rows(row, pivot_row)
            |> eliminate_column(row, col)

          {mat, row + 1, pivots ++ [col]}
      end
    end)
    |> then(fn {mat, _row, pivots} -> {mat, pivots} end)
  end

  defp find_pivot(matrix, start_row, col) do
    matrix
    |> Enum.with_index()
    |> Enum.drop(start_row)
    |> Enum.find_value(fn {row, idx} ->
      if Enum.at(row, col) == 1, do: idx, else: nil
    end)
  end

  defp swap_rows(matrix, i, i), do: matrix

  defp swap_rows(matrix, i, j) do
    row_i = Enum.at(matrix, i)
    row_j = Enum.at(matrix, j)

    matrix
    |> List.replace_at(i, row_j)
    |> List.replace_at(j, row_i)
  end

  defp eliminate_column(matrix, pivot_row, col) do
    pivot = Enum.at(matrix, pivot_row)

    Enum.with_index(matrix)
    |> Enum.map(fn
      {row, ^pivot_row} ->
        row

      {row, _idx} ->
        if Enum.at(row, col) == 1 do
          xor_rows(row, pivot)
        else
          row
        end
    end)
  end

  defp find_min_solution(matrix, pivots) do
    cols = length(hd(matrix)) - 1
    free_vars = Enum.filter(0..(cols - 1), &(&1 not in pivots))

    particular = particular_solution(matrix, pivots)
    nullspace = nullspace_vectors(matrix, pivots, free_vars)

    combinations(nullspace, length(particular))
    |> Enum.map(fn combo -> xor_rows(particular, combo) end)
    |> Enum.min_by(&Enum.sum/1)
  end

  defp particular_solution(matrix, pivots) do
    solution = List.duplicate(0, length(hd(matrix)) - 1)

    Enum.reduce(Enum.with_index(pivots), solution, fn {col, row}, acc ->
      List.replace_at(acc, col, Enum.at(Enum.at(matrix, row), -1))
    end)
  end

  defp nullspace_vectors(matrix, pivots, free_vars) do
    Enum.map(free_vars, fn free ->
      base = List.duplicate(0, length(hd(matrix)) - 1)
      base = List.replace_at(base, free, 1)

      Enum.reduce(Enum.with_index(pivots), base, fn {col, row}, acc ->
        val = Enum.at(Enum.at(matrix, row), free)
        List.replace_at(acc, col, val)
      end)
    end)
  end

  defp combinations(vectors, size) do
    zero = List.duplicate(0, size)

    Enum.reduce(vectors, [zero], fn v, acc ->
      acc ++ Enum.map(acc, &xor_rows(&1, v))
    end)
  end
end

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

  def solve_lights(machine) do
    matrix =
      Enum.map(Range.new(0, length(machine.lights) - 1), fn index ->
        Enum.map(machine.buttons, fn button ->
          if(index in button, do: 1, else: 0)
        end)
      end)

    GF2.solve(matrix, machine.target_lights) |> Enum.sum()
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
