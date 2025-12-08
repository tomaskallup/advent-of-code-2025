inputContent =
  File.read!("./inputs/day-4.txt")
  |> String.trim()
  |> String.split("\n")
  |> Enum.map(fn line -> String.graphemes(line) end)

defmodule Main do
  def checkRow(grid, row, index, acc) do
    _checkRowAndRemove(grid, length(Enum.at(grid, 0)), row, index, acc)
  end

  def _checkRows(grid, row, acc) when row >= length(grid), do: acc

  def _checkRows(grid, row, acc) do
    result = checkRow(grid, row, 0, acc)

    _checkRows(grid, row + 1, result)
  end

  def checkRows(grid) do
    _checkRows(grid, 0, %{count: 0, grid: grid})
  end

  def _checkRows2(grid, acc) do
    result = checkRows(grid)

    newAcc = acc + result.count

    # Optimization: Only recheck position around modified positions
    if result.count > 0 do
      _checkRows2(result.grid, newAcc)
    else
      newAcc
    end
  end

  def checkRows2(grid) do
    _checkRows2(grid, 0)
  end

  def _movable(grid, row, index, size) do
    cell = Enum.at(grid, row) |> Enum.at(index)

    neighbours = checkSquare(grid, row, index, size)

    result = if(cell == "@", do: neighbours <= 4, else: false)

    result
  end

  def _checkRowAndRemove(_grid, maxLen, _row, index, acc) when index >= maxLen do
    acc
  end

  def _checkRowAndRemove(grid, maxLen, row, index, acc) do
    if _movable(grid, row, index, 1) do
      newGrid =
        List.update_at(acc.grid, row, fn line ->
          line |> List.update_at(index, fn _ -> "x" end)
        end)

      newAcc = %{count: acc.count + 1, grid: newGrid}

      _checkRowAndRemove(grid, maxLen, row, index + 1, newAcc)
    else
      _checkRowAndRemove(grid, maxLen, row, index + 1, acc)
    end
  end

  def checkSquare(grid, row, index, size) do
    subset =
      Enum.slice(grid, Range.new(max(row - size, 0), min(row + size, length(grid))))
      |> Enum.flat_map(fn row ->
        row
        |> Enum.slice(Range.new(max(index - size, 0), min(index + size, length(row))))
        |> Enum.filter(fn char -> char == "@" end)
      end)

    length(subset)
  end
end

IO.puts("Part 1: #{Main.checkRows(inputContent).count}")
IO.puts("Part 2: #{Main.checkRows2(inputContent)}")
