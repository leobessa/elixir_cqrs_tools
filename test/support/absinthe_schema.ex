defmodule ChangeWidgetStatus do
  use Cqrs.Command

  field :status, :enum, values: [:new, :old]

  @impl true
  def handle_dispatch(command, _opts) do
    {:ok, command}
  end
end

defmodule WidgetTypes do
  use Cqrs.Absinthe
  use Absinthe.Schema.Notation

  derive_enum :widget_status, {ChangeWidgetStatus, :status}

  object :widget do
    field :status, :widget_status
  end
end

defmodule UserResolvers do
  def before_get_user_resolver(res, _) do
    send(self(), :before_resolve)
    res
  end
end

defmodule TempRepo do
  def all_users(_) do
    [
      %User{
        email: "chris@example.com",
        id: "052c1984-74c9-522f-858f-f04f1d4cc786",
        name: "chris"
      }
    ]
  end
end

defmodule UserTypes do
  use Cqrs.Absinthe
  use Cqrs.Absinthe.Relay
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
  end

  connection(node_type: :user)

  object :user_queries do
    derive_query GetUser, :user,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end

    derive_connection GetUsers, :user,
      repo: TempRepo,
      repo_fun: :all_users,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end

  object :user_mutations do
    derive_mutation CreateUser, :string,
      before_resolve: &UserResolvers.before_get_user_resolver/2,
      after_resolve: fn res, _ ->
        send(self(), :after_resolve)
        res
      end
  end
end

defmodule AbsintheSchema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types UserTypes
  import_types WidgetTypes

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_mutations
  end
end
