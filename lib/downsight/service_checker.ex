defmodule Downsight.ServiceChecker do
  alias Downsight.Repo
  import Ecto.Query
  import ExAws
  use GenServer


  @queue_url Application.fetch_env!(:downsight, :sqs_queue)
  def start_link(_opts) do
    IO.puts "Starting ServiceChecker"
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Implement a way to retry failed messages
  defp load_services do
    with op <- ExAws.SQS.receive_message(@queue_url, max_number_of_messages: 10, wait_time_seconds: 20),
    %{body: %{messages: messages}} <- ExAws.request!(op)
    do
      sevices = messages
      |> Enum.map(fn %{body: body} ->
        {:ok, service} = Jason.decode(body)
        service
      end)
      delete_batch = Enum.map(messages, fn %{message_id: id, receipt_handle: receipt_handle} ->
        %{id: id, receipt_handle: receipt_handle}
      end)
      ExAws.SQS.delete_message_batch(@queue_url, delete_batch)
      |> ExAws.request()
      sevices
    else
      _ -> IO.puts("oops")
    end

  end
  def check(%{"id" => id, "url" => url, "port" => port, "method" => method, "headers" => headers}) do
    url = URI.parse(url)
    url = %URI{url | port: port}
    headers = Jason.decode!(headers)
    {_, %Finch.Response{status: status}} =
      Finch.build(String.to_atom(method), URI.to_string(url), headers, nil)
      |> Finch.request(FinchClient)

    IO.inspect(status, label: "STATUS")
    case status do
      x when x >= 200 and x < 300 ->
        status_compare(:success, id)

      _ ->
        status_compare(:fail, id)
    end
  end

  def status_compare(:success, id) do
    IO.puts "Request with ID #{id} successful"
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
    IO.inspect(res)
  end

  def status_compare(:fail, id) do
    IO.puts "Request with ID #{id} failed"
    res =
      Repo.all(
        from s in Downsight.Service,
          where: s.id == ^id
      )
    IO.inspect(res)
  end

  @impl true
  def init(_opts) do
    services = load_services()
    Process.send_after(self(), :tick, 10000)
    {:ok, services}
  end


  @impl true
  def handle_call({:add_service, service}, _from, state) do
    {:reply, nil, state ++ [service]}
  end

  @impl true
  def handle_cast(:check_services, state) do
    IO.inspect(state, label: "Current state")

    Enum.map(state, fn service ->
      Task.async(fn -> check(service) end)
    end)
    |> Task.await_many()
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    IO.puts "Next Tick"
    GenServer.cast(__MODULE__, :check_services)
    Process.send_after(self(), :tick, 10000)
    {:noreply, state}
  end
end
