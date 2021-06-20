defmodule Cqrs.Absinthe.Errors do
  @moduledoc false
  def attach_error_handler(opts) do
    {provided_then, opts} = Keyword.pop(opts, :then, &Function.identity/1)
    Keyword.put(opts, :then, &handle_errors(&1, provided_then))
  end

  def handle_errors({:error, {:invalid_command, errors}}, _) do
    errors =
      Enum.flat_map(errors, fn
        {key, messages} -> Enum.map(messages, fn msg -> "#{key} #{msg}" end)
      end)

    {:error, errors}
  end

  def handle_errors(other, then) when is_function(then, 1) do
    then.(other)
  end
end