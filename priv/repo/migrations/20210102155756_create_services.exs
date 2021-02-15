defmodule Downsight.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :name, :string
      add :description, :string
      add :endpoint, :string
      add :manual_status, :string
      add :user_id, references(:users), null: false
      timestamps()
    end
  end
end
