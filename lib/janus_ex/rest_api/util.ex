defmodule JanusEx.RestApi.Util do
  def transaction() do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
  end
end
