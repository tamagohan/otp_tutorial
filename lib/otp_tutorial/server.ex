defmodule OtpTutorial.Server do
  def start(mod, initial_state) do
    spawn(fn -> init(mod, initial_state) end)
  end

  def start_link(mod, initial_state) do
    spawn_link(fn -> init(mod, initial_state) end)
  end

  def init(mod, initial_state) do
    loop(mod, mod.init(initial_state))
  end

  def loop(mod, state) do
    receive do
      {:async, msg} -> loop(mod, mod.handle_cast(msg, state))
      {:sync, pid, ref, msg}  -> loop(mod, mod.handle_call(msg, {pid, ref}, state))
    end
  end

  def call(pid, msg) do
    ref = Process.monitor(pid)
    send(pid, {:sync, self(), ref, msg})
    receive do
      {ref, reply_msg} ->
        Process.demonitor(ref, [:flush])
        reply_msg
      {:DOWN, _ref, :process, _pid, reason} ->
        raise(RuntimeError, message: "server down. reason: #{inspect reason}")
    after
      5_000 -> raise(RuntimeError, message: "timeout")
    end
  end

  def reply({pid, ref}, reply_msg) do
    send(pid, {ref, reply_msg})
  end

  def cast(pid, msg) do
    send(pid, {:async, msg})
    :ok
  end
end