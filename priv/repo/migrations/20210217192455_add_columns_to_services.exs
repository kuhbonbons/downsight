defmodule Downsight.Repo.Migrations.AddColumnsToServices do
  use Ecto.Migration

  def change do
    alter table("services") do
      remove :endpoint
      add :url, :string
      add :method, :string, default: "get"
      add :headers, :string, default: "[]"
      add :port, :integer, default: 80
    end
  end
end
