inputContent =
  File.read!("./inputs/day-1.txt")
  |> String.trim()
  |> String.replace("L", "-")
  |> String.replace("R", "+")
  |> String.split()

numbers = Enum.map(inputContent, fn x -> String.to_integer(x) end)

defmodule Main do
  def processNumbers(tail, accumulator \\ 50, part1 \\ 0, part2 \\ 0)

  def processNumbers([head | tail], accumulator, part1, part2) do
    rawNewAccumulator = accumulator + head
    newAccumulator = Integer.mod(rawNewAccumulator, 100)

    rotations =
      div(
        abs(rawNewAccumulator) + if(rawNewAccumulator <= 0 && accumulator > 0, do: 100, else: 0),
        100
      )

    newPart2 = part2 + rotations
    newPart1 = part1 + if(newAccumulator == 0, do: 1, else: 0)

    processNumbers(tail, newAccumulator, newPart1, newPart2)
  end

  def processNumbers([], _accumulator, part1, part2), do: %{part1: part1, part2: part2}
end

result = Main.processNumbers(numbers)

IO.puts("Part 1: #{result[:part1]}")
IO.puts("Part 2: #{result[:part2]}")
