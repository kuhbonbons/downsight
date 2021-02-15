defmodule Downsight.ServiceChecker do


  def check(%Downsight.Service{endpoint: endpoint, port: port, method: method, path: path, headers: headers}) do
    {:ok, conn} = Mint.HTTP.connect(:http, endpoint, port)
    {:ok, conn, ref} = Mint.HTTP.request(conn, method, path, headers, "")
    receive do
      message ->
        case Mint.HTTP.stream(conn, message) do
          :unknown -> IO.inspect(message)
          {:ok, conn, responses} ->
            case responses do
              {:status, _, 200} ->
                IO.puts("HELLO")
              _ -> IO.puts "hello"
        end
      end
    end
    Mint.HTTP.close(conn)
    conn
  end
end
