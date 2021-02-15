defmodule Downsight.Repo.Migrations.CreateIncident do
  use Ecto.Migration

  def change do
    create table(:incidents) do
      add :severity, :string
      add :resolved, :boolean
      add :service_id, references(:services), null: false
      timestamps()
    end
  end
end
