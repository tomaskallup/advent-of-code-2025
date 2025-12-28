inputContent =
  File.read!("./inputs/day-11.txt")
  |> String.trim()
  |> String.split("\n")

defmodule Parser do
  def parse_line(input) do
    [name | connections] = String.split(input, " ")

    {String.slice(name, 0..-2//1), connections}
  end

  def parse_lines(input),
    do:
      Enum.reduce(input, %{}, fn line, acc ->
        {key, value} = parse_line(line)
        Map.put(acc, key, value)
      end)
end

defmodule Main do
  def part1(device_map) do
    start_nodes = Map.get(device_map, "you")
    finish = "out"

    count_paths(start_nodes, finish, device_map)
  end

  defp count_paths(nodes, finish, device_map, visited \\ [], acc \\ 0)

  defp count_paths([], _finish, _map, _visited, acc), do: acc

  defp count_paths([node | rest], finish, device_map, visited, acc) do
    if(node == finish) do
      count_paths(rest, finish, device_map, visited, acc + 1)
    else
      new_visited = [node | visited]

      new_acc = count_paths(Map.get(device_map, node), finish, device_map, new_visited, acc)

      count_paths(rest, finish, device_map, new_visited, new_acc)
    end
  end

  def part2(device_map) do
    start_nodes = Map.get(device_map, "svr")
    finish = "out"

    {count, _memo} =
      count_paths2(start_nodes, finish, device_map, false, false, %{})

    count
  end

  defp count_paths2([], _finish, _map, _seen_dac, _seen_fft, memo),
    do: {0, memo}

  defp count_paths2([node | rest], finish, device_map, seen_dac, seen_fft, memo) do
    {count_node, memo} =
      count_from_node(node, finish, device_map, seen_dac, seen_fft, memo)

    {count_siblings, memo} =
      count_paths2(rest, finish, device_map, seen_dac, seen_fft, memo)

    {count_node + count_siblings, memo}
  end

  defp count_from_node(node, finish, _map, seen_dac, seen_fft, memo)
       when node == finish do
    count =
      if seen_dac and seen_fft, do: 1, else: 0

    {count, memo}
  end

  defp count_from_node(node, finish, device_map, seen_dac, seen_fft, memo) do
    key = {node, seen_dac, seen_fft}

    case memo do
      %{^key => value} ->
        {value, memo}

      _ ->
        new_seen_dac = seen_dac or node == "dac"
        new_seen_fft = seen_fft or node == "fft"

        {count, memo} =
          count_paths2(
            Map.get(device_map, node, []),
            finish,
            device_map,
            new_seen_dac,
            new_seen_fft,
            memo
          )

        {count, Map.put(memo, key, count)}
    end
  end
end

device_map = Parser.parse_lines(inputContent)

IO.puts("Part 1: #{Main.part1(device_map)}")
IO.puts("Part 2: #{Main.part2(device_map)}")
