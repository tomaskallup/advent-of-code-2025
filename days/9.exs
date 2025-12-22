inputContent =
  File.read!("./inputs/day-9.txt")
  |> String.trim()
  |> String.split("\n")

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

defmodule Utils do
  use Memoize

  def area({x1, y1}, {x2, y2}), do: (1 + abs(x1 - x2)) * (1 + abs(y1 - y2))

  def _check_intersection_horizontal({{rx1, ry1}, {rx2, ry2}}, {{x1, y1}, {x2, y2}}) do
    maxX = max(x1, x2)
    minX = min(x1, x2)
    maxY = max(y1, y2)
    minY = min(y1, y2)

    maxX >= rx2 and minX <= rx1 and maxY < ry2 and minY > ry1
  end

  def _check_intersection_vertical({{rx1, ry1}, {rx2, ry2}}, {{x1, y1}, {x2, y2}}) do
    maxX = max(x1, x2)
    minX = min(x1, x2)
    maxY = max(y1, y2)
    minY = min(y1, y2)

    maxY >= ry2 and minY <= ry1 and maxX < rx2 and minX > rx1
  end

  def point_in_rectangle({x, y}, {{rx1, ry1}, {rx2, ry2}}) do
    x > rx1 and y > ry1 and x < rx2 and y < ry2
  end

  def rectangle_in_polygon(rectangle, polygon) do
    Enum.all?(polygon, fn vertice ->
      # Is vertice point inside the rectangle?
      # Is vertice intersecting the rectangle?
      not point_in_rectangle(elem(vertice, 0), rectangle) and
        not _check_intersection_vertical(rectangle, vertice) and
        not _check_intersection_horizontal(rectangle, vertice)
    end)
  end
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
    item = {v, next, Utils.area(v, next)}

    map_vector(v, rest, [item | acc])
  end

  def create_map(vectors, acc \\ [])

  def create_map(vectors, acc) when length(vectors) < 2,
    do: acc |> Enum.sort_by(fn {_, _, area} -> area end, :desc)

  def create_map([v | others], acc) do
    create_map(others, acc ++ map_vector(v, others, []))
  end

  def make_polygon(vectors, vertices \\ [])

  def make_polygon([], vertices), do: vertices

  def make_polygon([point | rest], vertices) do
    if length(rest) == 0 do
      {start, _} = Enum.at(vertices, -1)
      make_polygon(rest, [{point, start} | vertices])
    else
      make_polygon(rest, [{point, Enum.at(rest, 0)} | vertices])
    end
  end

  def make_rec({x1, y1}, {x2, y2}) do
    {
      {min(x1, x2), min(y1, y2)},
      {max(x1, x2), max(y1, y2)}
    }
  end

  def filter_rectangles(v, others, polygon, acc \\ [])
  def filter_rectangles(_v, [], _polygon, acc), do: acc

  def filter_rectangles(v, [other | others], polygon, acc) do
    rectangle = make_rec(v, other)

    if Utils.rectangle_in_polygon(rectangle, polygon) do
      filter_rectangles(v, others, polygon, [other | acc])
    else
      filter_rectangles(v, others, polygon, acc)
    end
  end

  def create_map2(vectors, polygon, acc \\ [])

  def create_map2(vectors, _polygon, acc) when length(vectors) < 2,
    do: acc |> Enum.sort_by(fn {_, _, area} -> area end, :desc)

  def create_map2([v | others], polygon, acc) do
    candidates = filter_rectangles(v, others, polygon)

    create_map2(others, polygon, acc ++ map_vector(v, candidates, []))
  end
end

vectors = Main.parse(inputContent)
map = Main.create_map(vectors)
largest = Enum.at(map, 0)

IO.puts("Part 1: #{elem(largest, 2)}")

polygon = Main.make_polygon(vectors)
map2 = Main.create_map2(vectors, polygon)
largest2 = Enum.at(map2, 0)

IO.puts("Part 2: #{elem(largest2, 2)}")
