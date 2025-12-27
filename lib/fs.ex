defmodule FSUtil do
  @max_random_prefix 2 ** 32

  def with_temporary_files(basenames, fun) do
    dir = System.tmp_dir!()
    prefix = :rand.uniform(@max_random_prefix) |> Integer.to_string(32)

    paths =
      for basename <- basenames do
        Path.join(dir, "#{prefix}_#{basename}")
      end

    try do
      fun.(paths)
    after
      for path <- paths do
        try do
          File.rm!(path)
        rescue
          _ -> :ok
        end
      end
    end
  end
end
