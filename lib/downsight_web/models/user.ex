defmodule Downsight.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Downsight.User

  schema "users" do
    field :username, :string
    field :password, :string, redact: true
    field :email, :string
    has_many :services, Downsight.Service
    timestamps()
  end

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password, :email])
    |> validate_required([:username, :password, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
