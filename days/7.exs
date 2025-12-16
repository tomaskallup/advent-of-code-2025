inputContent =
  File.read!("./inputs/day-7.txt")
  |> String.trim()
  |> String.split("\n")
  |> Enum.map(&String.graphemes/1)

defmodule Main do
  def _continueBeam(row, x, _cell) when x < 0 or x >= length(row), do: row
  def _continueBeam(row, _x, cell) when cell == "|", do: row
  def _continueBeam(row, x, cell) when cell == ".", do: List.replace_at(row, x, "|")

  def _continueBeam(row, x, cell) do
    if cell == "^" do
      _continueBeam(row, x - 1, Enum.at(row, x - 1))
      |> _continueBeam(x + 1, Enum.at(row, x + 1))
    else
      row
    end
  end

  def continueBeam(row, x) do
    _continueBeam(row, x, Enum.at(row, x))
  end

  def _runRow(x, _y, maxX, grid) when x >= maxX, do: grid
  def _runRow(_x, y, _maxX, grid) when y >= length(grid) - 1, do: grid

  def _runRow(x, y, maxX, grid) do
    cell = Enum.at(grid, y) |> Enum.at(x)

    if cell == "|" or cell == "S" do
      nextRow = continueBeam(Enum.at(grid, y + 1), x)
      newGrid = List.replace_at(grid, y + 1, nextRow)

      _runRow(x + 1, y, maxX, newGrid)
    else
      _runRow(x + 1, y, maxX, grid)
    end
  end

  def runRow(index, grid) when index >= length(grid), do: grid

  def runRow(index, grid) do
    newGrid = _runRow(0, index, length(Enum.at(grid, index)), grid)

    runRow(index + 1, newGrid)
  end

  def _simulate(grid, row) when row >= length(grid), do: grid

  def _simulate(grid, row) do
    newGrid = runRow(row, grid)

    _simulate(newGrid, row + 1)
  end

  def simulate(grid) do
    _simulate(grid, 0)
  end

  def _countSplits([], _lastRow, acc), do: acc

  def _countSplits([row | rest], lastRow, acc) do
    rowCount =
      Enum.with_index(row)
      |> Enum.reduce(0, fn {x, index}, acc ->
        acc + if(x == "^" and Enum.at(lastRow, index) in ["|", "S"], do: 1, else: 0)
      end)

    _countSplits(rest, row, acc + rowCount)
  end

  def countSplits(grid) do
    [tail | rest] = grid

    _countSplits(rest, tail, 0)
  end

  def _updateSplitters([], _y, acc), do: acc

  def _updateSplitters([cell | rest], y, acc) do
    index = -length(rest) - 1

    newAcc =
      case cell do
        "^" ->
          List.update_at(acc, y, fn row ->
            List.update_at(row, index - 1, fn x ->
              x + (Enum.at(acc, y) |> Enum.at(index))
            end)
            |> List.update_at(index + 1, fn x ->
              x + (Enum.at(acc, y) |> Enum.at(index))
            end)
          end)

        _ ->
          acc
      end

    _updateSplitters(rest, y, newAcc)
  end

  def _updateBeams([], _y, acc), do: acc

  def _updateBeams([cell | rest], y, acc) do
    index = -length(rest) - 1

    newAcc =
      case cell do
        "S" ->
          List.update_at(acc, y + 1, fn row ->
            List.update_at(row, index, fn x -> x + 1 end)
          end)

        "|" ->
          List.update_at(acc, y + 1, fn row ->
            List.update_at(row, index, fn x ->
              x + (Enum.at(acc, y) |> Enum.at(index))
            end)
          end)

        _ ->
          acc
      end

    _updateBeams(rest, y, newAcc)
  end

  def _countPaths([], _y, acc), do: acc

  def _countPaths([row | rest], y, acc) do
    newAcc = _updateBeams(row, y, _updateSplitters(row, y, acc))

    _countPaths(rest, y + 1, newAcc)
  end

  def countTimelines(grid) do
    # Go top to bottom
    # If `S` hit, add 1 to cell below
    # If `|` hit, add its value to cell below
    # If `^` hit, add its value to both left & right
    # .......S....... .......S.......
    # .......|....... .......1.......
    # ......|^|...... ......1^1......
    # ......|.|...... ......1.1......
    # .....|^|^|..... .....1^2^1.....
    # .....|.|.|..... .....1.2.1.....
    # ....|^|^|^|.... ....1^3^3^1....
    # ....|.|.|.|.... ....1.3.3.1....
    # ...|^|^|||^|... ...1^4^331^1...
    # ...|.|.|||.|... ...1.4.331.1...
    # ..|^|^|||^|^|.. ..1^5^434^2^1..
    # ..|.|.|||.|.|.. ..1.5.434.2.1..
    # .|^|||^||.||^|. .1^154^74.21^1.
    # .|.|||.||.||.|. .1.154.74.21.1.
    # |^|^|^|^|^|||^| 1^2^@^!^!^211^1
    # |.|.|.|.|.|||.| 1.2.@.!.!.211.1 40 (@ = 10, ! = 11)
    rows = length(grid)
    cols = length(Enum.at(grid, 0))
    acc = for _ <- 1..rows, do: for(_ <- 1..cols, do: 0)

    counts = _countPaths(grid, 0, acc)

    Enum.sum(Enum.at(counts, -1))
  end
end

simulated = Main.simulate(inputContent)

splitCount = Main.countSplits(simulated)
timelineCount = Main.countTimelines(simulated)

IO.puts("Part 1: #{splitCount}")
IO.puts("Part 2: #{timelineCount}")
