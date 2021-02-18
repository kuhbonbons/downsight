defmodule Downsight.ServiceChecker do
  alias Downsight.Repo
  import Ecto.Query
  use GenServer

  def check(%Downsight.Service{id: id, url: url, port: port, method: method, headers: headers}) do
    url = URI.parse(url)
    url = %URI{url | port: port}

    {_, %Finch.Response{status: status}} =
      Finch.build(method, URI.to_string(url), headers, nil)
      |> Finch.request(FinchClient)

    case status do
      x when x >= 200 and x < 300 ->
        status_compare(:success, id)

      _ ->
        status_compare(:fail, id)
    end
  end

  def status_compare(:success, id) do
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
    IO.inspect(res)
  end

  def status_compare(:fail, id) do
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
  end

  @impl true
  def init(_opts) do
    {:ok, []}
  end


  @impl true
  def handle_call({:add_service, service}, _from, state) do
    {:reply, nil, state ++ [service]}
  end

  @impl true
  def handle_cast(:check_services, state) do
    Enum.map(state, fn service ->
      Task.async(check(service))
    end)
    |> Task.await_many()
    {:noreply, state}
  end
end
