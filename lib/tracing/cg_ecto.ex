defmodule CgExRay.Tracing.CgEcto do
  @doc """
  Convenience to retrieve the current CgEcto query as a string
  """
  def to_query(kind, repo, queryable) do
    {q, _} = repo.to_sql(kind, queryable)
    q |> String.replace("\"", "")
  end
end
