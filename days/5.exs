inputContent =
  File.read!("./inputs/day-5.txt")
  |> String.trim()
  |> String.split("\n")

defmodule Main do
  def _parseRange(input) do
    bounds = String.split(input, "-") |> Enum.map(fn x -> String.to_integer(x) end)

    apply(Range, :new, bounds)
  end

  def _parseRanges([head | tail], acc) when head == "", do: %{ranges: acc, rest: tail}

  def _parseRanges([head | tail], acc) do
    newAcc = [_parseRange(head) | acc]

    _parseRanges(tail, newAcc)
  end

  def parseRanges(input) do
    _parseRanges(input, [])
  end

  def parseInput(input) do
    rangeResult = parseRanges(input)

    items = rangeResult.rest |> Enum.map(fn x -> String.to_integer(x) end)

    %{ranges: rangeResult.ranges, items: items}
  end

  def _checkFresh([], _ranges, acc), do: acc

  def _checkFresh([item | rest], ranges, acc) do
    isInRange = Enum.any?(ranges, fn range -> item in range end)

    if(isInRange, do: _checkFresh(rest, ranges, acc + 1), else: _checkFresh(rest, ranges, acc))
  end

  def checkFresh(data) do
    _checkFresh(data.items, data.ranges, 0)
  end

  def _mergeRanges([], acc), do: acc

  def _mergeRanges([range | rest], acc) do
    jointIndex =
      Enum.find_index(acc, fn searchRange -> not Range.disjoint?(range, searchRange) end)

    if jointIndex do
      joint = Enum.at(acc, jointIndex)
      newRange = Range.new(min(joint.first, range.first), max(joint.last, range.last))
      newAcc = List.update_at(acc, jointIndex, fn _ -> newRange end)

      _mergeRanges(rest, newAcc)
    else
      _mergeRanges(rest, [range | acc])
    end
  end

  def mergeRanges(ranges) do
    sorted = Enum.sort_by(ranges, fn x -> x.first end)
    merged = _mergeRanges(sorted, [])

    merged
  end

  def getMembers(ranges) do
    merged = mergeRanges(ranges)

    Enum.map(merged, fn range -> Range.size(range) end) |> Enum.sum()
  end
end

data = Main.parseInput(inputContent)

IO.puts("Part 1: #{Main.checkFresh(data)}")
IO.puts("Part 2: #{Main.getMembers(data.ranges)}")
