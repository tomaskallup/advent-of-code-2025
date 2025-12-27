defmodule HiGHS do
  alias Dantzig.Solution

  def run_model(model_content) do
    FSUtil.with_temporary_files(["model.lp", "solution.lp"], fn [model_path, solution_path] ->
      File.write!(model_path, model_content)

      {output, _error_code} =
        System.cmd("highs", [
          model_path,
          "--solution_file",
          solution_path
        ])

      solution_contents =
        case File.read(solution_path) do
          {:ok, contents} ->
            contents

          {:error, :enoent} ->
            raise RuntimeError, """
            HiGHS failed to generate solution.

            Output from the HiGHS solver:

            #{output}
            """
        end

      Solution.from_file_contents!(solution_contents)
    end)
  end
end
