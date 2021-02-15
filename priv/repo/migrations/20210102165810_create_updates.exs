defmodule Downsight.Repo.Migrations.CreateUpdates do
  use Ecto.Migration

  def change do
    create table(:updates) do
      add :title, :string
      add :text, :string
      add :type, :string
      add :incident_id, references(:incidents), null: false
      timestamps()
    end
  end
end
