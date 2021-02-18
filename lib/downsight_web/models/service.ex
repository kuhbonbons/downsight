defmodule Downsight.Service do
  use Ecto.Schema
  import Ecto.Changeset
  alias Downsight.Service

  schema "services" do
    field :name, :string
    field :description, :string
    field :url, :string
    field :method, :string, default: "get"
    field :port, :integer, default: 80
    field :headers, :string, default: "[]"
    field :manual_status, :string
    belongs_to :user, Downsight.User
    has_many :incidents, Downsight.Incident
    timestamps()
  end

  def changeset(%Service{} = service, attrs) do
    service
    |> cast(attrs, [:name, :description, :url, :manual_status, :user_id])
    |> validate_required([:name, :manual_status])
    |> assoc_constraint(:user)
  end
end
