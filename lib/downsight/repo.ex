defmodule Downsight.Repo do
  use Ecto.Repo,
    otp_app: :downsight,
    adapter: Ecto.Adapters.MyXQL
end
