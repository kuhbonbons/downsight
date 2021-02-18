defmodule DownsightWeb.ServiceController do
  use DownsightWeb, :controller
  alias Downsight.Service
  alias Downsight.Repo

  def create(conn, body) do
    user =
      conn
      |> fetch_session()
      |> get_session(:us)

    body = Enum.into(body, %{"user_id" => user.id})
    change = Service.changeset(%Service{}, body)

    if change.valid? do
      try do
        Repo.insert!(change)
      catch
        _ ->
          conn
          |> send_resp(400, "Something is not right")
      end

      conn
      |> send_resp(204, "")
    else
      conn
      |> send_resp(400, "Something is not right")
    end
  end
end
