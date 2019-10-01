# ExApiTracing

Wrapper around [ex_ray](https://github.com/derailed/ex_ray) for OpenTrace in Elixir Phoenix. Initial implementation based on the [ex_ray_tracers](https://github.com/derailed/ex_ray_tracers), [phx_ex_ray](https://github.com/sashman/phx_ex_ray) example.

## Installation

This package is currently private for CG you can install by adding github url

```elixir
def deps do
  [
    {:ex_api_tracing, git: "git@github.com:CampGladiator/ex_api_tracing.git"}
  ]
end
```

## Usage

Configure [otter](https://github.com/Bluehouse-Technology/otter):

```elixir
config :otter,
  zipkin_collector_uri: 'http://127.0.0.1:9411/api/v1/spans',
  zipkin_tag_host_service: "cg-service",
```

> `zipkin_collector_uri` must be a char list

Configure application:

```elixir
# application.ex

...
ExRay.Store.create()
...
```

### Plug Usage

```elixir
# lib/my_app/endpoint.ex

...
use PrePlug

...
plug ExApiTracing.Plug.OpenTracing
plug ExApiTracing.Plug.CloseTracing
...
```

### Controller Usage

Cross controller set up:

```elixir
# lib/my_app/my_app_web.ex

def controller do
  quote do
    ...
    import ExApiTracing.Span
    ...
  end
end
```

Then in a specific controller:

```elixir
use ExApiTracing.Span, :controller

@trace kind: :action
def index(conn, _params) do
  ...
end
```

### Database Context Usage

In a context, or any file where you use `alias MyApp.Repo`:

```elixir
use ExApiTracing.Span, {:context, MyApp.Repo}

...
@trace query: :list_all_users, kind: :all, queryable: User
def list_users() do
  Repo.all(User)
end

# or

@trace query: :get_user_by_id, sql: "SELECT * FROM users WHERE (id = X)"
def get_user!(id), do: Repo.get!(User, id)
```
