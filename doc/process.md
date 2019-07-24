# プロセス

Erlang VM上でのプロセスの生成やプロセス間でどのようにメッセージをやり取りするかについて説明する。
ここで扱うプロセスとはErlang VM上でErlangのschedulerによって管理されるものでOSのプロセスとは異なる。

プロセスの見え方としては単なる関数に過ぎず、関数の実行が終わったら消える。
(実際にはメッセージのメールボックスなどいくつかの状態を隠し持っているが、ここでは関数的な側面を紹介する)


* プロセスを生成([`spawn`](https://hexdocs.pm/elixir/Kernel.html#spawn/1))する
  ```
  > spawn(fn -> IO.puts "#{1 + 1}" end)
  ```
  * `spawn`の返り値はプロセス識別子(pid)である
* プロセスの実行順は保証されない
  ```
  > Enum.each(1..10, fn x -> spawn(fn -> IO.inspect x end) end)
  ```
  * Erlangのschedulerが状況に合わせてプロセスをスケジューリングする

* メッセージを送信([`send`](https://hexdocs.pm/elixir/Kernel.html#send/2))する
  ```
  > send(self(), "hello")
  > flush
  ```
  * `self()`は自分自身(つまりiexのpid)
* メッセージを受信する
  ```
  > pid = spawn(&OtpTutorial.Dolphin.dolphin1/0)
  > send(pid, "oh, hello dolphin!")

  # これには反応しない
  > send(pid, "fish")

  # 再起動
  > pid = spawn(&OtpTutorial.Dolphin.dolphin1/0)
  > send(pid, "fish")
  ```
* メッセージに返信する
  ```
  > pid = spawn(&OtpTutorial.Dolphin.dolphin2/0)
  > send(pid, {self(), "do_a_flip"})
  > flush
  ```
* プロセスを生かし続ける
  ```
  > pid = spawn(&OtpTutorial.Dolphin.dolphin3/0)
  > send(pid, {self(), "do_a_flip"})
  > send(pid, {self(), "do_a_flip"})
  > flush
  ```

# プロセスの監視

* [`link`](https://hexdocs.pm/elixir/Process.html#link/1)
  ```
  # 5秒後に死ぬ(exit)
  > spawn(fn -> Process.sleep(5_000); exit("reason") end)

  > self()
  > Process.link(spawn(fn -> Process.sleep(5_000); exit("reason") end))
  > self()
  ```
  * linkはプロセスとプロセスをリンクさせ、片方のプロセスが死んだときにシグナル(今までやり取りしてたメッセージとは異なる)が送られる
  * このメッセージはtry catchなどではキャッチできない
  * 死ぬタイミングが同じであるようなプロセス間で利用する
  * `spawn/1`と`link/1`をアトミックに行うことができる[`spawn_link/1`](https://hexdocs.pm/elixir/Kernel.html#spawn_link/1)が存在する
    * これがないと、spawnしてからlinkするまでにprocessが死んだときに取りこぼす。(そのため基本的には`spawn_link/1`を使う)
* シグナルをキャッチする
  ```
  > Process.flag(:trap_exit, true)
  > self()
  > Process.link(spawn(fn -> Process.sleep(5_000); exit("reason") end))
  > self()
  > flush
  ```
* [`monitor`](https://hexdocs.pm/elixir/Process.html#monitor/1)
  * 必ずしもいつも自分が死んだときに道連れにする必要はない
  * 監視できればいいだけの場合が多い
  * `monitor/1`は`link/1`と下記の点で異なる
    * 一方向である
    * 2つのプロセス間で複数のモニターが持てる(それぞれに識別子がある)
  * `spawn_monitor`/1でspawnとmonitorをatomicに実施できる
  * 監視しているプロセスが死んだときにメッセージを受け取れる
    ```
    > spawn_monitor(fn -> Process.sleep(5_000) end)
    > flush

    # exitで殺す
    > spawn_monitor(fn -> Process.sleep(5_000); exit("reason") end)
    > flush
    ```
  * 監視をやめる
    ```
    > {pid, ref} = spawn_monitor(fn ->
        receive do
         _ -> exit("reason")
        end
      end)
    > send(pid, :die)
    > flush()


    > {pid, ref} = spawn_monitor(fn ->
        receive do
         _ -> exit("reason")
        end
      end)
    > Process.demonitor(ref)
    > send(pid, :die)
    > flush()
    ```
# プロセスに名前をつける

* 批評家に音楽を批評してもらう
  ```
  > pid = OtpTutorial.Critic.start_critic()
  > OtpTutorial.Critic.judge(pid, "Genesis", "The Lambda Lies Down on Broadway")
  ```
  * 太陽風(solar storm)のせいで批評家が死んでしまった
  ```
  > Process.exit(pid, "solar storm")
  > OtpTutorial.Critic.judge(pid, "Genesis", "The Lambda Lies Down on Broadway")
  ```
  * timeoutまでまつのがだるい
* 批評家を蘇生させるためのsupervisorを作る
  * 蘇生したときにpidは変わってしまうので今までどおり、pidを直接してメッセージを送るということができない。
  * processに名前をつけよう
  ```
  > OtpTutorial.Critic.start_critic2()
  > Process.exit(Process.whereis(Critic), "solar storm")
  > OtpTutorial.Critic.judge2("Genesis", "The Lambda Lies Down on Broadway")
  ```
* 上記のコードだと下記の場合におかしいことになる
  1. criticにメッセージを送信
  1. criticがreceive
  1. criticが応答
  1. criticが死亡
  1. criticが再開
  1. judgeのwhereisが再開後のcriticのpidを取得(ここはタイミング依存)
  1. receiveでマッチしない
* つまりpidを使って識別すべきでない。pidを使わない方法でmessageを識別しよう。
  ```
  > OtpTutorial.Critic.start_critic3
  > OtpTutorial.Critic.judge3("Genesis", "The Lambda Lies Down on Broadway")
  ```
