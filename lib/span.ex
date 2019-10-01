defmodule ExApiTracing.Span do
  alias ExRay.Span
  alias ExRay.Store
  alias ExApiTracing.Tracing.ExPhx
  alias ExApiTracing.Tracing.ExEcto

  def controller do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      def start_span(ctx) do
        conn = ctx.args |> List.first
        trace_id = conn |> ExPhx.trace_id
        span_name = "#{ExPhx.controller_name(conn)} #{ExPhx.action_name(conn)}"

        Process.put(:trace_id, conn |> ExPhx.trace_id)

        span_name
        |> Span.open(trace_id)
        |> :otter.tag(:component, "controller")
        |> :otter.tag(:kind, ctx.meta[:kind])
        |> :otter.tag(:controller, conn |> ExPhx.controller_name)
        |> :otter.tag(:action, conn |> ExPhx.action_name)
        |> :otter.log(">>> Starting action #{conn |> ExPhx.action_name} at #{conn.request_path}")
      end

      def end_span(ctx, span, _rendered) do
        conn = ctx.args |> List.first
        trace_id = conn |> ExPhx.trace_id
        tracestore = Store.get(trace_id)
        if length(tracestore) > 0 do
          controller_span = span
          |> :otter.log("<<< Ending action #{conn |> ExPhx.action_name}")
          |> Span.close(trace_id)
        end
      end
    end
  end

  def context(repo) do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      defp trace_id() do
        case Process.get(:trace_id) do
          nil -> "trace_id_missing"
          trace_id -> trace_id
        end
      end

      defp start_span(ctx) do
        ctx.target
        |> Span.open(trace_id())
        |> :otter.tag(:component, "database")
        |> :otter.tag(:query, ctx.meta[:query])
      end

      defp end_span(ctx, p_span, _return) do
        p_span
        |> :otter.log(log_query_string(ctx.meta))
        |> Span.close(trace_id())
      end

      defp log_query_string([_, kind: kind, queryable: queryable, count: count]) do
        query = ExEcto.exec_query(unquote(repo), count)
        if length(query) do
          query = query |> List.insert_at(1, ["\\n"])
        else
          query = ExEcto.to_query(kind, unquote(repo), queryable)
        end
        query
      end
      defp log_query_string([_, kind: kind, queryable: queryable]) do
        query = ExEcto.exec_query(unquote(repo))
        if !length(query) do
          query = ExEcto.to_query(kind, unquote(repo), queryable)
        end
        query
      end
      defp log_query_string([_, sql: string]), do: string
      defp log_query_string(_meta), do: "Query not specified"
    end
  end

  def message do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      defp trace_id() do
        case Process.get(:trace_id) do
          nil -> "trace_id_missing"
          trace_id -> trace_id
        end
      end

      def start_span(ctx) do
        ctx.target
        |> Span.open(trace_id())
        |> :otter.tag(:component, "kafka")
        |> :otter.tag(:topic, ctx.meta[:topic])
        |> :otter.tag(:source, Mix.Project.config[:app])
        |> :otter.tag(:action, ctx.meta[:action])
        |> :otter.tag(:target, ctx.target)
        |> :otter.tag(:data, ctx.args |> List.first)
        |> :otter.log("Kafka Message")
      end

      def end_span(_, p_span, _rendered) do
        p_span |> Span.close(trace_id())
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({:context, repo}) do
    apply(__MODULE__, :context, [repo])
  end
end
