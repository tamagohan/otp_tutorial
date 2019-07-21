# OtpTutorial

## Installation

```elixir
$ asdf install
$ iex -S mix
```

# NaiveKittyServer

```elixir
> cat1 = OtpTutorial.NaiveKittyServer.order_cat(pid, "carl", "brown", "loves to burn bridges")
%OtpTutorial.NaiveKittyServer.Cat{
  color: "brown",
  description: "loves to burn bridges",
  name: "carl"
}

> OtpTutorial.NaiveKittyServer.return_cat(pid, cat1)
:ok

# Top priority on store profits
> OtpTutorial.NaiveKittyServer.order_cat(pid, "jimmy", "orange", "cuddly")
%OtpTutorial.NaiveKittyServer.Cat{
  color: "brown",
  description: "loves to burn bridges",
  name: "carl"
}

> OtpTutorial.NaiveKittyServer.order_cat(pid, "jimmy", "orange", "cuddly")
%OtpTutorial.NaiveKittyServer.Cat{
  color: "orange",
  description: "cuddly",
  name: "jimmy"
}

> OtpTutorial.NaiveKittyServer.return_cat(pid, cat1)
:ok

> OtpTutorial.NaiveKittyServer.close_shop(pid)
carl was set free.
:ok

# The store is already closed
> OtpTutorial.NaiveKittyServer.close_shop(pid)
** (RuntimeError) server down. reason: :noproc
    (otp_tutorial) lib/otp_tutorial/naive_kitty_server.ex:70: OtpTutorial.NaiveKittyServer.close_shop/1
```