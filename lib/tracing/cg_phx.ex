defmodule CgExRay.Tracing.CgPhx do
  @moduledoc """
  A set of convenience function to deal with Phoenix
  """

  @trace_field_header "x_instana_trace_id"

  @doc """
  Extract the action name from a Phoenix controller
  """
  # @spec action_name(Plug.Conn.t) :: String.t
  def action_name(conn) do
    conn |> Phoenix.Controller.action_name
  end

  @doc """
  Retrieves the Phoenix controller name
  """
  # @spec controller_name(Plug.Conn.t) :: String.t
  def controller_name(conn) do
    conn |> Phoenix.Controller.controller_module |> demodulize
  end

  @doc """
  Name the span after the current action
  """
  # @spec span_name(Plug.Conn.t) :: String.t
  def span_name(conn) do
    [
      conn.scheme |> Atom.to_string |> String.upcase,
      conn.method,
      conn.request_path
    ]
    |> Enum.join(" ")
  end

  @doc """
  Extract the unique request ID from a connection. This ID will
  be used to uniquely identify the span chain
  """
  # @spec request_id(Plug.Conn.t) :: number
  def request_id(conn) do
    conn.resp_headers
    |> Enum.filter(fn
      ({"x-request-id", _}) -> true
      ({_, _})              -> false
    end)
    |> List.first
    |> (fn({_, req_id}) -> req_id end).()
  end

  def trace_id(conn) do
    case List.keyfind(conn.req_headers, @trace_field_header, 0) do
      {@trace_field_header, instana_trace_id} -> instana_trace_id
      _ -> request_id(conn)
    end
  end

  def errorStack(conn) do
    if conn.status == 500 do
      stacktrace = Process.info(conn.owner, :current_stacktrace)
      {:current_stacktrace, stacktraces} = stacktrace
      stacktraces
    else
      nil
    end
  end

  defp demodulize(mod) do
    mod
    |> Atom.to_string
    |> String.split(".")
    |> List.last
    |> String.replace("Controller", "")
  end
end
