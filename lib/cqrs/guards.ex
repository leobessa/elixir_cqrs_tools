defmodule Cqrs.Guards do
  @moduledoc false

  def ensure_is_struct!(_module) do
    # unless exports_function?(module, :__struct__, 0) do
    #   raise "#{module |> Module.split() |> Enum.join(".")} should be a valid struct."
    # end
  end

  def ensure_is_command!(_module) do
    # unless exports_function?(module, :__command__, 0) do
    #   raise InvalidCommandError, command: module
    # end
  end

  def ensure_is_query!(_module) do
    # unless exports_function?(module, :__query__, 0) do
    #   raise InvalidQueryError, query: module
    # end
  end

  def ensure_is_dispatcher!(_module) do
    # unless exports_function?(module, :dispatch, 2) do
    #   raise InvalidDispatcherError, dispatcher: module
    # end
  end

  def exports_function?(module, fun, arity) do
    case Code.ensure_compiled(module) do
      {:module, _} -> function_exported?(module, fun, arity)
      _ -> false
    end
  end
end
