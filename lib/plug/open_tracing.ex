defmodule CgExRay.Plug.OpenTracing do
  @behaviour Plug

  alias ExRay.Span
  alias CgExRay.Tracing.CgPhx

  def init(default), do: default

  def call(conn, _) do
    trace_id = conn |> CgPhx.trace_id
    Process.put(:trace_id, trace_id)

    conn
    |> CgPhx.span_name
    |> Span.open(trace_id)
    |> :otter.tag(:component, "router")
    |> :otter.log(">>> Starting Request at #{conn.request_path}")

    conn
  end
end
