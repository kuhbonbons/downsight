defmodule Downsight.Update do
  use Ecto.Schema
  import Ecto.Changeset
  alias Downsight.Update

  schema "updates" do
    field :title, :string
    field :text, :string
    field :type, :string
    belongs_to :incident, Downsight.Incident
    timestamps()
  end

  def changeset(%Update{} = update, attrs) do
    update
    |> cast(attrs, [:title, :text, :type])
    |> validate_required([:title, :text, :type])
  end
end
