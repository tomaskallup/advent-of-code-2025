inputContent =
  File.read!("./inputs/day-2.txt")
  |> String.trim()
  |> String.split(",")

defmodule Main do
  def parseInput(input, acc \\ [])

  def parseInput([head | tail], acc) do
    newAcc = [parseRange(head) | acc]

    parseInput(tail, newAcc)
  end

  def parseInput([], acc), do: acc

  def parseRange([head]), do: String.to_integer(head)

  def parseRange([head | tail]), do: %{from: parseRange([head]), to: parseRange(tail)}

  def parseRange(str) do
    str
    |> String.split("-")
    |> parseRange()
  end

  def checkID2(str) do
    doubled = str <> str
    inner = String.slice(doubled, 1, byte_size(doubled) - 2)

    String.contains?(inner, str)
  end

  def checkID(str) when rem(byte_size(str), 2) == 1, do: false

  def checkID(str) when rem(byte_size(str), 2) == 0 do
    n = div(byte_size(str), 2)
    <<first::binary-size(n), second::binary-size(n)>> = str

    first == second
  end

  def checkRange(from, to, acc \\ %{part1: 0, part2: 0})

  def checkRange(from, to, acc) when from > to, do: acc

  def checkRange(from, to, acc) do
    newAcc = %{
      part1: acc.part1 + if(checkID(Integer.to_string(from)), do: from, else: 0),
      part2: acc.part2 + if(checkID2(Integer.to_string(from)), do: from, else: 0)
    }

    checkRange(from + 1, to, newAcc)
  end

  def checkRange(%{from: from, to: to}), do: checkRange(from, to)

  def checkRanges(ranges, acc \\ %{part1: 0, part2: 0})

  def checkRanges([], acc), do: acc

  def checkRanges([range | tail], acc) do
    rangeResult = checkRange(range)

    newAcc = %{
      part1: acc.part1 + rangeResult.part1,
      part2: acc.part2 + rangeResult.part2
    }

    checkRanges(tail, newAcc)
  end
end

ranges = Main.parseInput(inputContent)

result = Main.checkRanges(ranges)

IO.puts("Part 1: #{result.part1}")
IO.puts("Part 2: #{result.part2}")
