defmodule DownsightWeb.UserController do
  use DownsightWeb, :controller
  alias Downsight.Repo
  import Ecto.Query
  alias Downsight.User

  def create(conn, user) do
    user = %{user | "password" => Bcrypt.hash_pwd_salt(user["password"])}
    change = User.changeset(%User{}, user)
    if change.valid? do
      Repo.insert(change)

      conn
      |> send_resp(204, "")
    else
      conn
      |> send_resp(400, "Something is not right")
    end
  end

  def session(conn, _params) do
    case conn |> fetch_session() |> get_session(:us) do
      user when is_nil(user) -> conn |> send_resp(403, "")
      user -> conn |> json(%{username: user.username, email: user.email})
    end
  end
  def login(conn, %{"username" => username, "password" => password}) do
    with [found] <-
           Repo.all(
             from u in User,
               where: u.username == ^username
           ),
         true <- Bcrypt.verify_pass(password, found.password) do
      conn
      |> fetch_session()
      |> put_session(:us, found)
      |> send_resp(204, "")
    else
      _ ->
        conn
        |> send_resp(403, "User not found")
    end

  end

  def login(conn, _) do
    conn
    |> send_resp(400, "There was something wrong with the request.")
  end
end
