inputContent =
  File.read!("./inputs/day-8.txt")
  |> String.trim()
  |> String.split("\n")

defmodule Vector do
  def add({x1, y1, z1}, {x2, y2, z2}), do: {x1 + x2, y1 + y2, z1 + z2}
  def reverse({x, y, z}), do: {-x, -y, -z}
  def subtract(a, b), do: add(a, reverse(b))

  def vec_length({0, 0, 0}), do: 0
  def vec_length({x, y, z}), do: :math.sqrt(:math.pow(x, 2) + :math.pow(y, 2) + :math.pow(z, 2))

  def distance(v1, v2), do: subtract(v1, v2) |> vec_length()

  def vec_get({x, _, _}, :x), do: x
  def vec_get({_, y, _}, :y), do: y
  def vec_get({_, _, z}, :z), do: z
end

defmodule Main do
  def _parse([], acc), do: Enum.reverse(acc)

  def _parse([row | rest], acc) do
    item = String.split(row, ",") |> Enum.map(&String.to_integer/1) |> List.to_tuple()

    _parse(rest, [item | acc])
  end

  def parse(input) do
    _parse(input, [])
  end

  def map_vector(_v, [], acc), do: acc

  def map_vector(v, [next | rest], acc) do
    item = {v, next, Vector.distance(v, next)}

    map_vector(v, rest, [item | acc])
  end

  def create_map(vectors, acc \\ [])

  def create_map(vectors, acc) when length(vectors) < 2, do: acc |> Enum.sort_by(fn {_, _, distance} -> distance end)

  def create_map([v | others], acc) do
    create_map(others, acc ++ map_vector(v, others, []))
  end

  def _connect_boxes(vec1, vec2, nil, nil, circuts),
    do: [[vec1, vec2] | circuts]

  def _connect_boxes(_vec1, vec2, index, nil, circuts),
    do: List.update_at(circuts, index, fn circut -> [vec2 | circut] end)

  def _connect_boxes(_vec1, _vec2, index1, index2, circuts) when index1 == index2,
    do: circuts

  def _connect_boxes(vec1, _vec2, nil, index, circuts),
    do: List.update_at(circuts, index, fn circut -> [vec1 | circut] end)

  def _connect_boxes(_vec1, _vec2, index1, index2, circuts),
    do:
      List.update_at(circuts, index1, fn circut -> circut ++ Enum.at(circuts, index2) end)
      |> List.delete_at(index2)

  def _create_connections([], _count, circuts), do: {[], circuts}
  # Early termination
  def _create_connections(map, count, circuts) when length(circuts) == 1 or count <= 0,
    do: {map, circuts}

  def _create_connections([pair | rest], count, circuts) do
    {vec1, vec2, _} = pair

    vec1_circut = Enum.find_index(circuts, fn circut -> vec1 in circut end)
    vec2_circut = Enum.find_index(circuts, fn circut -> vec2 in circut end)

    newCircuts = _connect_boxes(vec1, vec2, vec1_circut, vec2_circut, circuts)

    _create_connections(rest, count - 1, newCircuts)
  end

  def create_connections(vector_map, count, circuts) do
    {restMap, circuts} = _create_connections(vector_map, count, circuts)
    {restMap, circuts |> Enum.sort_by(&length/1, :desc)}
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

vectors = Main.parse(inputContent)
map = Main.create_map(vectors)
baseCircuts = Enum.map(vectors, fn vec -> [vec] end)

{restMap, circuts} = Main.create_connections(map, 1000, baseCircuts)

IO.puts("Part 1: #{Enum.take(circuts, 3) |> Enum.reduce(1, fn x, acc -> length(x) * acc end)}")

# Use previous result to just continue
{newMap, _} = Main.create_connections(restMap, length(restMap), circuts)

lastConnection = Enum.at(map, -length(newMap) - 1)
{vec1, vec2, _} = lastConnection
product = Tuple.product({Vector.vec_get(vec1, :x), Vector.vec_get(vec2, :x)})

IO.puts("Part 2: #{product}")
