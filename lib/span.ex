defmodule CgExRay.Span do
  alias ExRay.Span
  alias ExRay.Store
  alias CgExRay.Tracing.CgPhx
  alias CgExRay.Tracing.CgEcto

  def controller do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      def start_span(ctx) do
        conn = ctx.args |> List.first
        request_id = conn |> CgPhx.request_id
        span_name = "#{CgPhx.controller_name(conn)} #{CgPhx.action_name(conn)}"

        Process.put(:request_id, conn |> CgPhx.request_id)

        span_name
        |> Span.open(request_id)
        |> :otter.tag(:component, "controller")
        |> :otter.tag(:kind, ctx.meta[:kind])
        |> :otter.tag(:controller, conn |> CgPhx.controller_name)
        |> :otter.tag(:action, conn |> CgPhx.action_name)
        |> :otter.log(">>> Starting action #{conn |> CgPhx.action_name} at #{conn.request_path}")
      end

      def end_span(ctx, span, _rendered) do
        conn = ctx.args |> List.first
        request_id = conn |> CgPhx.request_id

        tracestore = Store.get(request_id)
        if length(tracestore) > 0 do
          controller_span = span
          |> :otter.log("<<< Ending action #{conn |> CgPhx.action_name}")
          |> Span.close(request_id)
        end
      end
    end
  end

  def context(repo) do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      defp request_id() do
        case Process.get(:request_id) do
          nil -> "request_id_missing"
          request_id -> request_id
        end
      end

      defp start_span(ctx) do
        ctx.target
        |> Span.open(request_id())
        |> :otter.tag(:component, "database")
        |> :otter.tag(:query, ctx.meta[:query])
        |> :otter.log(log_query_string(ctx.meta))
      end

      defp end_span(ctx, p_span, _ret) do
        p_span |> Span.close(request_id())
      end

      defp log_query_string([_, kind: kind, queryable: queryable]) do
        CgEcto.to_query(kind, unquote(repo), queryable)
      end
      defp log_query_string([_, sql: string]), do: string
      defp log_query_string(_meta), do: "Query not specified"
    end
  end

  def message do
    quote do
      use ExRay, pre: :start_span, post: :end_span

      defp request_id() do
        case Process.get(:request_id) do
          nil -> "request_id_missing"
          request_id -> request_id
        end
      end

      def start_span(ctx) do
        ctx.target
        |> Span.open(request_id())
        |> :otter.tag(:component, "kafka")
        |> :otter.tag(:topic, ctx.meta[:topic])
        |> :otter.tag(:source, Mix.Project.config[:app])
        |> :otter.tag(:action, ctx.meta[:action])
        |> :otter.tag(:target, ctx.target)
        |> :otter.tag(:data, ctx.args |> List.first)
        |> :otter.log("Kafka Message")
      end

      def end_span(_, p_span, _rendered) do
        p_span |> Span.close(request_id())
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
