defmodule Engine.TestUtil do
  def fixture(name, type \\ :json) do
    path = "test/fixtures/#{Atom.to_string(name)}.#{type}"
    File.read!(path)
  end

  def run_spec_fixture(opts \\ []) do
    OpenFn.RunSpec
    |> struct!(
      Enum.into(opts, %{
        expression_path: write_temp!(~s[alterState((state) => state)]),
        state_path: write_temp!(~s[{"foo": "bar"}]),
        language_pack: "@openfn/language-common",
        final_state_path: Temp.path!()
      })
    )
  end

  defp write_temp!(contents) do
    File.write!(path = Temp.path!(), contents)
    path
  end

  import ExUnit.Assertions

  def has_ok_results(runs) do
    assert length(runs) > 0

    assert Enum.all?(runs, fn %OpenFn.Run{result: result} ->
             case result do
               %OpenFn.Result{} = result ->
                 result.exit_code == 0

               _ ->
                 false
             end
           end)
  end
end
