# defmodule PriceRegister.Release do
#   @app :price_register

#   def migrate do
#     for repo <- repos() do
#       {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
#     end
#   end

#   def rollback(repo, version) do
#     {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
#   end

#   def seed do
#     for repo <- repos() do
#       seed_script = seeds_path(repo)

#       if File.exists?(seed_script) do
#         Code.eval_file(seed_script)
#       end
#     end
#   end

#   defp repos do
#     Application.load(@app)
#     Application.fetch_env!(@app, :ecto_repos)
#   end

#   defp seeds_path(repo), do: priv_path_for(repo, "seeds.exs")

#   defp priv_path_for(repo, filename) do
#     app = Keyword.get(repo.config, :otp_app)
#     repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
#     Path.join([priv_dir(app), repo_underscore, filename])
#   end

#   defp priv_dir(app), do: "#{:code.priv_dir(app)}"
# end
