defmodule PriceRegister.Release do
  use PriceRegister.Repo
  @app :price_register
  @start_apps [
    :postgrex,
    :ecto
  ]

  def migrate do
    prepare()
    Enum.each(repos(), &run_migrations_for/1)
  end

  def seed do
    prepare()
    Enum.each(repos(), &run_seeds_for/1)
  end

  def rollback do
    prepare()
    Enum.each(repos(), fn repo -> run_rollbacks_for(repo, 1) end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp run_seeds_for(repo) do
    seed_script = seeds_path(repo)

    if File.exists?(seed_script) do
      Code.eval_file(seed_script)
    end
  end

  defp run_migrations_for(repo) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  defp run_rollbacks_for(repo, step) do
    app = Keyword.get(repo.config, :otp_app)

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, all: false, step: step))
  end

  defp prepare do
    :ok = Application.load(@app)

    Enum.each(@start_apps, &Application.ensure_all_started/1)

    Enum.each(repos(), & &1.start_link(pool_size: 2))
  end

  defp seeds_path(repo), do: priv_path_for(repo, "seeds.exs")

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    Path.join([priv_dir(app), repo_underscore, filename])
  end

  defp priv_dir(app), do: "#{:code.priv_dir(app)}"
end
