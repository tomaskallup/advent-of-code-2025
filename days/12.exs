inputContent =
  File.read!("./inputs/day-12.txt")
  |> String.trim()
  |> String.split("\n")

defmodule Parser do
  defp shape_to_map_set(shape) do
    shape
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, y} ->
      row
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.flat_map(fn
        {?#, x} -> [{x, y}]
        _ -> []
      end)
    end)
    |> MapSet.new()
  end

  defp parse_shape("", shape), do: {:done, shape_to_map_set(Enum.reverse(shape))}

  defp parse_shape(line, shape) do
    cond do
      line =~ ~r/^[#.]+$/ ->
        {:cont, [line | shape]}

      line =~ ~r/^\d+x\d+:/ ->
        {:halt}

      true ->
        {:cont, shape}
    end
  end

  defp parse_shapes(lines) do
    Enum.reduce_while(lines, {[], 0, []}, fn line, {shapes, acc, shape} ->
      case parse_shape(line, shape) do
        {:cont, shape} ->
          {:cont, {shapes, acc + 1, shape}}

        {:done, shape} ->
          {:cont, {[shape | shapes], acc + 1, []}}

        {:halt} ->
          {:halt, {Enum.reverse(shapes), Enum.drop(lines, acc)}}
      end
    end)
  end

  defp parse_counts(bin, current \\ 0, acc \\ [])

  defp parse_counts(<<>>, current, acc),
    do: Enum.reverse([current | acc])

  defp parse_counts(<<" ", rest::binary>>, current, acc),
    do: parse_counts(rest, 0, [current | acc])

  defp parse_counts(<<digit, rest::binary>>, current, acc)
       when digit in ?0..?9 do
    parse_counts(rest, current * 10 + (digit - ?0), acc)
  end

  defp parse_region(line) do
    [size, rest] = :binary.split(line, ": ")
    {size, parse_counts(rest)}
  end

  defp parse_regions(lines, acc \\ [])

  defp parse_regions([], acc), do: Enum.reverse(acc)

  defp parse_regions([line | rest], acc) do
    parse_regions(rest, [parse_region(line) | acc])
  end

  def parse_lines(input) do
    {shapes, rest} = parse_shapes(input)
    regions = parse_regions(rest)

    {shapes, regions}
  end
end

defmodule Main do
  defp region_to_map({size, _}) do
    [w, h] = String.split(size, "x") |> Enum.map(&String.to_integer/1)

    {MapSet.new(
       for x <- 0..(w - 1),
           y <- 0..(h - 1),
           do: {x, y}
     ), {w, h}}
  end

  def bounds(shape) do
    Enum.reduce(shape, {0, 0}, fn {x, y}, {mx, my} ->
      {max(x, mx), max(y, my)}
    end)
  end

  defp generate_placements(shape_orientations, {_region, {w, h}}) do
    Enum.flat_map(shape_orientations, fn shape ->
      {max_x, max_y} = bounds(shape)

      for x <- 0..(w - max_x - 1),
          y <- 0..(h - max_y - 1) do
        shape
        |> Enum.map(fn {sx, sy} -> {sx + x, sy + y} end)
        |> MapSet.new()
      end
    end)
  end

  def validate_region(region, oriented_shapes) do
    {_, counts} = region
    {region_map, {w, h}} = region_to_map(region)

    area_needed = calculate_area_needed(counts, oriented_shapes)

    if area_needed > w * h do
      false
    else
      all_placements = generate_all_placements(oriented_shapes, {region_map, {w, h}})

      required_shapes =
        counts
        |> Enum.with_index()
        |> Enum.flat_map(fn {quantity, index} ->
          Enum.map(1..quantity, fn _ -> index end)
        end)

      solve_placement_sequence(region_map, all_placements, required_shapes, MapSet.new())
    end
  end

  defp calculate_area_needed(counts, oriented_shapes) do
    counts
    |> Enum.with_index()
    |> Enum.reduce(0, fn {count, index}, acc ->
      if count == 0 do
        acc
      else
        shape_size =
          oriented_shapes
          |> Enum.at(index)
          |> hd()
          |> MapSet.size()

        acc + count * shape_size
      end
    end)
  end

  defp generate_all_placements(oriented_shapes, region_info) do
    oriented_shapes
    |> Enum.with_index()
    |> Enum.map(fn {shape_orientations, index} ->
      {index, generate_placements(shape_orientations, region_info)}
    end)
    |> Enum.into(%{})
  end

  defp solve_placement_sequence(_region_map, _all_placements, [], _used_positions) do
    true
  end

  defp solve_placement_sequence(
         region_map,
         all_placements,
         [shape_index | remaining_shapes],
         used_positions
       ) do
    possible_placements = Map.get(all_placements, shape_index, [])

    Enum.any?(possible_placements, fn placement ->
      if MapSet.disjoint?(placement, used_positions) do
        new_used_positions = MapSet.union(used_positions, placement)
        solve_placement_sequence(region_map, all_placements, remaining_shapes, new_used_positions)
      else
        false
      end
    end)
  end

  defp validate_regions([], _shapes, acc), do: acc

  defp validate_regions([region | rest], shapes, acc) do
    region_ok = validate_region(region, shapes)

    IO.puts("Region #{elem(region, 0)} validated: #{region_ok}")

    validate_regions(rest, shapes, acc + if(region_ok, do: 1, else: 0))
  end

  # Move shape back to 0,0
  defp normalize(shape) do
    {min_x, min_y} =
      shape
      |> Enum.reduce({:infinity, :infinity}, fn {x, y}, {mx, my} ->
        {min(x, mx), min(y, my)}
      end)

    shape
    |> Enum.map(fn {x, y} -> {x - min_x, y - min_y} end)
    |> MapSet.new()
  end

  defp rotate(shape) do
    shape
    |> Enum.map(fn {x, y} -> {y, -x} end)
    |> MapSet.new()
    |> normalize()
  end

  defp flip(shape) do
    shape
    |> Enum.map(fn {x, y} -> {-x, y} end)
    |> MapSet.new()
    |> normalize()
  end

  defp orientations(shape) do
    r0 = normalize(shape)
    r1 = rotate(r0)
    r2 = rotate(r1)
    r3 = rotate(r2)

    [r0, r1, r2, r3]
    |> Enum.flat_map(fn r -> [r, flip(r)] end)
    |> Enum.uniq()
  end

  def part1(shapes, regions) do
    oriented_shapes = Enum.map(shapes, &orientations/1)

    validate_regions(regions, oriented_shapes, 0)
  end
end

{shapes, regions} = Parser.parse_lines(inputContent)

IO.puts("Part 1: #{Main.part1(shapes, regions)}")
