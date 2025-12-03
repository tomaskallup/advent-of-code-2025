inputContent =
  File.read!("./inputs/day-3.txt")
  |> String.trim()
  |> String.split("\n")

defmodule Main do
  # Bank = 987654321111111
  def parseBank(input, acc \\ [])

  def parseBank([head | tail], acc) do
    newAcc = [head - ?0 | acc]

    parseBank(tail, newAcc)
  end

  def parseBank([], acc), do: acc

  def parseBank(input, acc) do
    parseBank(input |> :binary.bin_to_list() |> Enum.reverse(), acc)
  end

  def parseBanks([head | tail], acc) do
    newAcc = [parseBank(head) | acc]

    parseBanks(tail, newAcc)
  end

  def parseBanks([], acc), do: acc

  def parseBanks(input) do
    parseBanks(input, [])
  end

  def searchDigit([], _digit), do: %{ok: false, rest: []}

  def searchDigit(input, digit, wantedLen) when length(input) < wantedLen or digit < 0,
    do: %{ok: false, rest: []}

  def searchDigit([first | rest], digit, wantedLen) do
    if(first == digit, do: %{ok: true, rest: rest}, else: searchDigit(rest, digit, wantedLen))
  end

  def searchDigits_(haystack, digit, count, acc) do
    result = searchDigit(haystack, digit, count)

    if(result.ok,
      do: %{newAcc: acc <> "#{digit}", rest: result.rest},
      else: searchDigits_(haystack, digit - 1, count, acc)
    )
  end

  def searchDigits(haystack, count, acc \\ "")

  def searchDigits(_haystack, count, acc) when count <= 0, do: acc

  # 911023
  def searchDigits(haystack, count, acc) do
    result = searchDigits_(haystack, 9, count, acc)

    searchDigits(result.rest, count - 1, result.newAcc)
  end
end

banks = Main.parseBanks(inputContent)

part1 =
  banks
  |> Enum.map(fn bank -> String.to_integer(Main.searchDigits(bank, 2)) end)
  |> Enum.sum()

part2 =
  banks
  |> Enum.map(fn bank -> String.to_integer(Main.searchDigits(bank, 12)) end)
  |> Enum.sum()

IO.puts("Part 1: #{part1}")
IO.puts("Part 2: #{part2}")
