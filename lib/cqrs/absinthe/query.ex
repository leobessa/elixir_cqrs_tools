if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Query do
    @moduledoc false
    alias Cqrs.{BoundedContext, Absinthe.Args, Absinthe.Metadata, Absinthe.Middleware}

    def create_connection_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)

      opts =
        :cqrs_tools
        |> Application.get_env(:absinthe_relay, [])
        |> Keyword.merge(opts)

      repo = Keyword.fetch!(opts, :repo)

      quote do
        require Middleware

        connection field unquote(function_name), node_type: unquote(returns) do
          unquote_splicing(query_args)

          Middleware.before_resolve(unquote(query_module), unquote(opts))

          resolve(fn args, resolution ->
            alias Absinthe.Relay.Connection

            opts = Metadata.merge(resolution, unquote(opts))

            case BoundedContext.__create_query__(unquote(query_module), args, opts) do
              {:error, error} ->
                {:error, error}

              {:ok, query} ->
                repo_fun = fn args ->
                  fun = Keyword.get(unquote(opts), :repo_fun, :all)
                  apply(unquote(repo), fun, [args])
                end

                Connection.from_query(query, repo_fun, args)
            end
          end)

          Middleware.after_resolve(unquote(query_module), unquote(opts))
        end
      end
    end

    def create_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)

      quote do
        require Middleware

        field unquote(function_name), unquote(returns) do
          unquote_splicing(query_args)

          Middleware.before_resolve(unquote(query_module), unquote(opts))

          resolve(fn attrs, resolution ->
            opts =
              resolution
              |> Metadata.merge(unquote(opts))
              |> Keyword.put(:tag?, true)

            BoundedContext.__execute_query__(unquote(query_module), attrs, opts)
          end)

          Middleware.after_resolve(unquote(query_module), unquote(opts))
        end
      end
    end

    defp create_query_args(query_module, opts) do
      query_module.__filters__()
      |> Args.extract_args(opts)
      |> Enum.map(fn {name, absinthe_type, required, opts} ->
        case required do
          true -> quote do: arg(unquote(name), non_null(unquote(absinthe_type)), unquote(opts))
          false -> quote do: arg(unquote(name), unquote(absinthe_type), unquote(opts))
        end
      end)
    end
  end
end
