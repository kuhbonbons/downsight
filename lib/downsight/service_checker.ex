defmodule Downsight.ServiceChecker do
  alias Downsight.Repo
  import Ecto.Query
  require Logger
  use GenServer


  @queue_url Application.fetch_env!(:downsight, :sqs_queue)
  def start_link(_opts) do
    Logger.info("Starting ServiceChecker")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Implement a way to retry failed messages
  defp load_services do
    Logger.info("Loading Services...")
    with op <- ExAws.SQS.receive_message(@queue_url, max_number_of_messages: 10, wait_time_seconds: 20),
    %{body: %{messages: messages}} <- ExAws.request!(op)
    do
      services = messages
      |> Enum.map(fn %{body: body} ->
        {:ok, service} = Jason.decode(body)
        service
      end)
      delete_batch = Enum.map(messages, fn %{message_id: id, receipt_handle: receipt_handle} ->
        %{id: id, receipt_handle: receipt_handle}
      end)
      ExAws.SQS.delete_message_batch(@queue_url, delete_batch)
      |> ExAws.request()
      Logger.debug(services)
      services
    else
      _ -> IO.puts("oops")
    end

  end
  def check(%{"id" => id, "url" => url, "port" => port, "method" => method, "headers" => headers}) do
    Logger.info("Sending Requests...")
    url = URI.parse(url)
    url = %URI{url | port: port}
    headers = Jason.decode!(headers)
    {_, %Finch.Response{status: status}} =
      Finch.build(String.to_atom(method), URI.to_string(url), headers, nil)
      |> Finch.request(FinchClient)
    case status do
      x when x >= 200 and x < 300 ->
        status_compare(:success, id)

      _ ->
        status_compare(:fail, id)
    end
  end

  def status_compare(:success, id) do
    Logger.debug("Request with ID #{id} was successful")
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
    Logger.debug(res)
  end

  def status_compare(:fail, id) do
    Logger.debug("Request with ID #{id} has failed")
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
    Logger.debug(res)
  end

  @impl true
  def init(_opts) do
    Process.send_after(self(), :tick, 10000)
    {:ok, []}
  end


  @impl true
  def handle_call({:add_service, service}, _from, state) do
    {:reply, nil, state ++ [service]}
  end

  def handle_call(:load_services, _from, _state) do
    services = load_services()
    {:reply, nil, services}
  end

  @impl true
  def handle_cast(:check_services, state) do
    Enum.map(state, fn service ->
      Task.async(fn -> check(service) end)
    end)
    |> Task.await_many()
    {:noreply, []}
  end

  @impl true
  def handle_info(:tick, _state) do
    services = load_services()
    GenServer.cast(__MODULE__, :check_services)
    Process.send_after(self(), :tick, 10000)
    {:noreply, services}
  end
end
