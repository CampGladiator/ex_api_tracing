defmodule ExApiTracing.Tracing.ExEcto do
  @doc """
  Get the last executed query from the postgres activity
  """
  def exec_query(repo, count \\ 1) do
    result = Ecto.Adapters.SQL.query!(
      repo, "SELECT \"query\" from pg_stat_activity WHERE (\"query\" <> '') IS NOT FALSE AND \"query\" NOT LIKE '%pg_stat_activity%'", []
    )
    result.rows |> Enum.take(count)
  end
  @doc """
  Convenience to retrieve the current ExEcto query as a string
  """
  def to_query(kind, repo, queryable) do
    {q, _} = repo.to_sql(kind, queryable)
    q |> String.replace("\"", "")
  end
end
