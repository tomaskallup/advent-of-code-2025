inputContent =
  File.read!("./inputs/day-6.txt")
  |> String.split("\n")
  |> Enum.filter(fn x -> byte_size(x) > 0 end)

defmodule Main do
  defmodule Problem do
    defstruct values: [], operator: nil, index: nil, length: nil
  end

  def updateProblem(problem, input) do
    inputTrimmed = String.trim(input)

    case input do
      _ when inputTrimmed in ["+", "*"] ->
        %Problem{
          values: problem.values,
          operator: inputTrimmed,
          index: problem.index,
          length: problem.length
        }

      _ ->
        %Problem{
          values: [input | problem.values],
          operator: problem.operator,
          index: problem.index,
          length: problem.length
        }
    end
  end

  def parseLine(line, acc) do
    chunks = Enum.map(acc, fn problem -> String.slice(line, problem.index, problem.length) end)

    newAcc =
      Enum.with_index(acc)
      |> Enum.map(fn {problem, index} -> updateProblem(problem, Enum.at(chunks, index)) end)

    newAcc
  end

  def parseLines([], acc) do
    # Make sure values are in correct order
    Enum.map(acc, fn problem ->
      %Problem{
        values: Enum.reverse(problem.values),
        operator: problem.operator,
        index: problem.index,
        length: problem.length
      }
    end)
  end

  def parseLines([line | rest], acc) do
    newAcc = parseLine(line, acc)

    parseLines(rest, newAcc)
  end

  def parseProblems(input) do
    lastLine = Enum.at(input, length(input) - 1)

    columns =
      String.graphemes(lastLine)
      |> Enum.with_index()
      |> Enum.reduce([], fn {char, index}, acc ->
        if(char !== " ", do: [index | acc], else: acc)
      end)
      |> Enum.reverse()

    problems = columns |> Enum.map(fn index -> %Problem{index: index} end)

    problemsWithLength =
      Enum.with_index(problems)
      |> Enum.reverse()
      |> Enum.map(fn {problem, index} ->
        %Problem{
          index: problem.index,
          length:
            if(index >= length(columns) - 1,
              do: byte_size(lastLine),
              else: Enum.at(columns, index + 1)
            ) - problem.index
        }
      end)

    parseLines(input, problemsWithLength)
  end

  def _sum(numbers), do: Enum.sum(numbers)
  def _mult(numbers), do: Enum.reduce(numbers, 1, fn num, acc -> num * acc end)

  def calculateProblem(problem) do
    numbers = problem.values |> Enum.map(fn x -> String.trim(x) |> String.to_integer() end)

    if problem.operator === "+" do
      _sum(numbers)
    else
      _mult(numbers)
    end
  end

  def calculateProblems([], acc), do: acc

  def calculateProblems([problem | rest], acc) do
    calculateProblems(rest, acc + calculateProblem(problem))
  end

  def calculateProblems2([], acc), do: acc

  def calculateProblems2([problem | rest], acc) do
    transposed =
      problem.values
      |> Enum.map(&String.graphemes/1)
      |> Enum.zip()
      |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join() |> String.trim() end)
      |> Enum.filter(fn x -> byte_size(x) > 0 end)

    calculateProblems2(
      rest,
      acc + calculateProblem(%Problem{values: transposed, operator: problem.operator})
    )
  end
end

problems = Main.parseProblems(inputContent)
IO.puts("Part 1: #{Main.calculateProblems(problems, 0)}")
IO.puts("Part 2: #{Main.calculateProblems2(problems, 0)}")
