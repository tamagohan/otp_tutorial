defmodule OtpTutorial.NaiveKittyServer do
  defmodule Cat do
    defstruct [:name, :color, :description]
  end

  def start_link() do
    spawn_link(&init/0)
  end

  def init() do
    loop([])
  end

  def loop(cats) do
    receive do
      {pid, ref, {:order, name, color, description}} ->
        if Enum.empty?(cats) do
          send(pid, {ref, make_cat(name, color, description)})
          loop(cats)
        else
          send(pid, {ref, hd(cats)})
          loop(tl(cats))
        end
      {:return, cat} ->
        loop([cat | cats])
      {pid, ref, :terminate} ->
        send(pid, {ref, :ok})
        terminate(cats)
      unknown ->
        IO.puts("unknown message: #{inspect unknown}")
    end
  end

  defp make_cat(name, color, description) do
    %Cat{name: name, color: color, description: description}
  end

  defp terminate(cats) do
    Enum.each(cats, fn cat -> IO.puts("#{cat.name} was set free.") end)
    :ok
  end

  def order_cat(pid, name, color, description) do
    ref = Process.monitor(pid)
    send(pid, {self(), ref, {:order, name, color, description}})
    receive do
      {ref, cat} ->
        Process.demonitor(ref, [:flush])
        cat
      {:DOWN, _ref, :process, _pid, reason} ->
        raise(RuntimeError, message: "server down. reason: #{inspect reason}")
    after
      5_000 -> raise(RuntimeError, message: "timeout")
    end
  end

  def return_cat(pid, cat) do
    send(pid, {:return, cat})
    :ok
  end

  def close_shop(pid) do
    ref = Process.monitor(pid)
    send(pid, {self(), ref, :terminate})
    receive do
      {ref, :ok} ->
        Process.demonitor(ref, [:flush])
        :ok
      {:DOWN, _ref, :process, _pid, reason} ->
        raise(RuntimeError, message: "server down. reason: #{inspect reason}")
    after
      5_000 -> raise(RuntimeError, message: "timeout")
    end
  end
end