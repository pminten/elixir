Code.require_file "../../test_helper.exs", __DIR__

defmodule Mix.Tasks.App.StartTest do
  use MixTest.Case

  defmodule AppStartSample do
    def project do
      [app: :app_start_sample, version: "0.1.0"]
    end
  end

  defmodule WrongElixirProject do
    def project do
      [app: :error, version: "0.1.0", elixir: "~> 0.8.1"]
    end
  end

  test "recompiles project if elixir version changed" do
    Mix.Project.push MixTest.Case.Sample

    in_fixture "no_mixfile", fn ->
      Mix.Tasks.Compile.run []
      purge [A, B, C]

      assert_received { :mix_shell, :info, ["Compiled lib/a.ex"] }
      assert System.version == Mix.Deps.Lock.elixir_vsn

      Mix.Task.clear
      File.write!("_build/shared/lib/sample/.compile.lock", "the_past")
      File.touch!("_build/shared/lib/sample/.compile.lock", { { 2010, 1, 1 }, { 0, 0, 0 } })

      Mix.Tasks.App.Start.run ["--no-start", "--no-compile"]
      assert System.version == Mix.Deps.Lock.elixir_vsn
      assert File.stat!("_build/shared/lib/sample/.compile.lock").mtime > { { 2010, 1, 1 }, { 0, 0, 0 } }
    end
  after
    Mix.Project.pop
  end

  test "compiles and starts the project" do
    Mix.Project.push AppStartSample

    in_fixture "no_mixfile", fn ->
      assert_raise Mix.Error, fn ->
        Mix.Tasks.App.Start.run ["--no-compile"]
      end

      Mix.Tasks.App.Start.run ["--no-start"]
      assert File.regular?("_build/shared/lib/app_start_sample/ebin/Elixir.A.beam")
      assert File.regular?("_build/shared/lib/app_start_sample/ebin/app_start_sample.app")
      refute List.keyfind(:application.loaded_applications, :app_start_sample, 0)

      Mix.Tasks.App.Start.run []
      assert List.keyfind(:application.loaded_applications, :app_start_sample, 0)
    end
  after
    Mix.Project.pop
  end

  test "validates the Elixir version requirement" do
    Mix.Project.push WrongElixirProject

    in_fixture "no_mixfile", fn ->
      error = assert_raise Mix.ElixirVersionError, fn ->
        Mix.Tasks.App.Start.run ["--no-start"]
      end

      assert error.message =~ %r/ to run :error /
    end
  after
    purge [A, B, C]
    Mix.Project.pop
  end

  test "does not validate the Elixir version requirement when disabled" do
    Mix.Project.push WrongElixirProject

    in_fixture "no_mixfile", fn ->
      Mix.Tasks.App.Start.run ["--no-start", "--no-elixir-version-check"]
    end
  after
    purge [A, B, C]
    Mix.Project.pop
  end
end
