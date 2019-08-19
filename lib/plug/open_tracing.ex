defmodule CgExRay.Plug.OpenTracing do
  @behaviour Plug

  alias ExRay.Span
  alias CgExRay.Tracing.CgPhx

  def init(default), do: default

  def call(conn, _) do
    Process.put(:request_id, conn |> CgPhx.request_id)

    # look for trace id in the request header to
    trace_id = case List.keyfind(conn.req_headers, "x_instana_trace_id", 0) do
      {"x_instana_trace_id", instana_trace_id} -> instana_trace_id
      _ -> conn |> CgPhx.request_id
    end

    conn
    |> CgPhx.span_name
    |> Span.open(trace_id)
    |> :otter.tag(:component, "router")
    |> :otter.log(">>> Starting Request at #{conn.request_path}")

    conn
  end
end
