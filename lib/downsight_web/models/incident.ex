defmodule Downsight.Incident do
  use Ecto.Schema
  import Ecto.Changeset
  alias Downsight.Incident

  schema "incidents" do
    field :severity, :string
    field :resolved, :boolean
    belongs_to :service, Downsight.Service
    has_many :updates, Downsight.Update
    timestamps()
  end

  def changeset(%Incident{} = incident, attrs) do
    incident
    |> cast(attrs, [:severity, :resolved])
    |> validate_required([:severity, :resolved])
  end
end
