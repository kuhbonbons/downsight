defmodule Downsight.Service do
  use Ecto.Schema
  import Ecto.Changeset
  alias Downsight.Service

  schema "services" do
    field :name, :string
    field :description, :string
    field :endpoint, :string
    field :method, :string
    field :port, :integer
    field :path, :string
    field :headers, :string
    field :manual_status, :string
    belongs_to :user, Downsight.User
    has_many :incidents, Downsight.Incident
    timestamps()
  end

  def changeset(%Service{} = service, attrs) do
    service
    |> cast(attrs, [:name, :description, :enpoint, :manual_status])
    |> validate_required([:name, :manual_status])
  end
end
