defmodule CgExRay.Plug.CloseTracing do
  @behaviour Plug

  import Plug.Conn

  alias ExRay.Span
  alias ExRay.Store
  alias CgExRay.Tracing.CgPhx

  def init(opts), do: opts

  def call(conn, _opts) do
    register_before_send(conn, fn(conn) ->
      request_id = conn |> CgPhx.request_id
      # stacktraces = conn |> CgPhx.errorStack
      stacktraces = if conn.status == 500 do Process.info(conn.owner, :current_stacktrace) else nil end
      traceStore = Store.get(request_id)

      if length(traceStore) == 2 do
        Store.current(request_id)
        |> :otter.tag(:component, "controller")
        |> :otter.tag(:controller, conn |> CgPhx.controller_name)
        |> :otter.tag(:action, conn |> CgPhx.action_name)
        |> :otter.log("Controller action #{conn |> CgPhx.action_name}")
        |> Span.close(request_id)
      end

      case Store.current(request_id) do
        nil -> nil
        parent_span -> parent_span
        |> :otter.tag(:scheme, conn.scheme)
        |> :otter.tag(:host, conn.host)
        |> :otter.tag(:method, conn.method)
        |> :otter.tag(:request_path, conn.request_path)
        |> :otter.tag(:query_string, conn.query_string)
        |> :otter.tag(:status, conn.status)
        |> :otter.tag(:resp_body, conn.resp_body)
        |> :otter.tag(:stacktrace, stacktraces)
        |> :otter.log("Request completed.")
        |> Span.close(request_id)
      end

      conn
    end)
  end
end
