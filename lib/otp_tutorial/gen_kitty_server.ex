defmodule OtpTutorial.GenKittyServer do
  use GenServer

  defmodule Cat do
    defstruct [:name, :color, :description]
  end

  # Server functions
  @impl true
  def init([]) do
    {:ok, []}
  end

  @impl true
  def handle_call({:order, name, color, description}, _from, cats) do
    if Enum.empty?(cats) do
      {:reply, make_cat(name, color, description), cats}
    else
      {:reply, hd(cats), tl(cats)}
    end
  end

  @impl true
  def handle_call(:terminate, _from, cats) do
    {:stop, :normal, :ok, cats}
  end

  @impl true
  def handle_cast({:return, cat}, cats) do
    {:noreply, [cat | cats]}
  end

  @impl true
  def handle_info(msg, _cats) do
    IO.puts("Unexpected message: #{inspect msg}")
  end

  @impl true
  def terminate(:normal, cats) do
    Enum.each(cats, fn cat -> IO.puts("#{cat.name} was set free.") end)
    :ok
  end

  # Private functions
  defp make_cat(name, color, description) do
    %Cat{name: name, color: color, description: description}
  end

  # Synchronous call
  def order_cat(pid, name, color, description) do
    GenServer.call(pid, {:order, name, color, description})
  end

  # Asynchronous call
  def return_cat(pid, cat) do
    GenServer.cast(pid, {:return, cat})
  end

  # Synchronous call
  def close_shop(pid) do
    GenServer.call(pid, :terminate)
  end
end