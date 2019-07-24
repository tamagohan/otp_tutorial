defmodule OtpTutorial.Critic do
  def start_critic() do
    spawn(__MODULE__, :critic, [])
  end

  def judge(pid, band, album) do
    send(pid, {self(), {band, album}})
    receive do
      # criticからのmessageであることをpidでマッチさせることで確認
      {^pid, criticism} -> criticism
    after 2_000 ->
      :timeout
    end
  end

  def critic() do
    receive do
      {from, {"Rage Against the Turning Machine", "Unit Testify"}} ->
        send(from, {self(), "They are great!"})
      {from, {"System of a Downtime", "Memoize"}} ->
        send(from, {self(), "They're not Johny Crash but they're good."})
      {from, {"Johny Crash", "The Token Ring of Fire"}} ->
        send(from, {self(), "Simply incredeible"})
      {from, {_band, _album}} ->
        send(from, {self(), "They are terrible!"})
    end
  end

  def start_critic2() do
    spawn(__MODULE__, :restarter, [])
  end

  def restarter() do
    Process.flag(:trap_exit, true)
    pid = spawn_link(__MODULE__, :critic, [])
    # プロセスに名前をつける
    # 名前をつけないとrestarterがプロセスを再起動した際に新しいプロセスのpidをクライアントは知ることができない
    Process.register(pid, Critic)
    receive do
      {:EXIT, _pid, :normal}   -> :ok # not a crash
      {:EXIT, _pid, :shutdown} -> :ok # manual termination, not a crash
      {:EXIT, _pid, _}         -> restarter(); IO.puts("restarted")
    end
  end

  def judge2(band, album) do
    send(Critic, {self(), {band, album}})
    pid = Process.whereis(Critic)
    receive do
      {^pid, criticism} -> criticism
    after 2_000 ->
      :timeout
    end
  end

  def start_critic3() do
    spawn(__MODULE__, :restarter3, [])
  end

  def restarter3() do
    Process.flag(:trap_exit, true)
    pid = spawn_link(__MODULE__, :critic3, [])
    Process.register(pid, Critic)
    receive do
      {:EXIT, _pid, :normal}   -> :ok # not a crash
      {:EXIT, _pid, :shutdown} -> :ok # manual termination, not a crash
      {:EXIT, _pid, _}         -> restarter3(); IO.puts("restarted")
    end
  end

  def judge3(band, album) do
    ref = make_ref()
    send(Critic, {self(), ref, {band, album}})
    receive do
      {^ref, criticism} -> criticism
    after 2_000 ->
      :timeout
    end
  end

  def critic3() do
    receive do
      {from, ref, {"Rage Against the Turning Machine", "Unit Testify"}} ->
        send(from, {ref, "They are great!"})
      {from, ref, {"System of a Downtime", "Memoize"}} ->
        send(from, {ref, "They're not Johny Crash but they're good."})
      {from, ref, {"Johny Crash", "The Token Ring of Fire"}} ->
        send(from, {ref, "Simply incredeible"})
      {from, ref, {_band, _album}} ->
        send(from, {ref, "They are terrible!"})
    end
  end
end