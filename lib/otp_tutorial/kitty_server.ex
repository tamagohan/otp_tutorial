defmodule OtpTutorial.KittyServer do
  alias OtpTutorial.Server
  defmodule Cat do
    defstruct [:name, :color, :description]
  end

  # Client API
  def start_link() do
    Server.start_link(__MODULE__, [])
  end

  # Server functions
  def init([]) do
    []
  end

  def handle_call({:order, name, color, description}, from, cats) do
    if Enum.empty?(cats) do
      Server.reply(from, make_cat(name, color, description))
      cats
    else
      Server.reply(from, hd(cats))
      tl(cats)
    end
  end

  def handle_call(:terminate, from, cats) do
    Server.reply(from, :ok)
    terminate(cats)
  end

  def handle_cast({:return, cat}, cats) do
    [cat | cats]
  end

  # Private functions
  defp make_cat(name, color, description) do
    %Cat{name: name, color: color, description: description}
  end

  defp terminate(cats) do
    Enum.each(cats, fn cat -> IO.puts("#{cat.name} was set free.") end)
    exit(:normal)
  end

  # Synchronous call
  def order_cat(pid, name, color, description) do
    Server.call(pid, {:order, name, color, description})
  end

  # Asynchronous call
  def return_cat(pid, cat) do
    Server.cast(pid, {:return, cat})
  end

  # Synchronous call
  def close_shop(pid) do
    Server.call(pid, :terminate)
  end
end