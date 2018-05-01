defmodule ProfitBricks do

  @moduledoc """
  Documentation for ProfitBricks.
  """

  use Tesla, only: [:head, :get, :post, :put, :patch, :delete]

  @api_endpoint_default "https://api.profitbricks.com/cloudapi/v4"

  plug Tesla.Middleware.Tuples, rescue_errors: :all
  plug Tesla.Middleware.BaseUrl, Application.get_env(:profitbricks_api_wrapper, :api_endpoint, @api_endpoint_default)
  plug Tesla.Middleware.Headers, make_auth_header()
  plug Tesla.Middleware.JSON
  plug ForceEmptyBodyAndContentTypeForDelete
  if Application.get_env(:profitbricks_api_wrapper, :http_retry_enabled, true) do
    plug Tesla.Middleware.Retry, delay: Application.get_env(:profitbricks_api_wrapper, :http_retry_delay, 1000), max_retries: Application.get_env(:profitbricks_api_wrapper, :http_retry_max_retries, 5)
  end
  if Application.get_env(:profitbricks_api_wrapper, :http_follow_redirects, true) do
    plug Tesla.Middleware.FollowRedirects
  end
  if Application.get_env(:profitbricks_api_wrapper, :debug_http, false) do
    plug Tesla.Middleware.DebugLogger
  end

  def make_auth_header() do
    %{"Authorization" => "Basic " <> Base.encode64(Application.fetch_env!(:profitbricks_api_wrapper, :username) <> ":" <> Application.fetch_env!(:profitbricks_api_wrapper, :password))}
  end

  # ProfitBricks API doesn't allow post requests that are supposed to have no
  # data to declare an application/json data content type. So here, build a
  # custom, single arg POST function that skips the content type.
  def post(path) do
    headers = Map.merge(make_auth_header(), %{"Content-Type" => "application/x-www-form-urlencoded"})
    response = Tesla.post(Application.get_env(:profitbricks_api_wrapper, :api_endpoint, @api_endpoint_default) <> path, "", headers: headers)
    {:ok, response}
    rescue
      error ->
        {:error, error}
  end

end

# This is necessary because ProfitBricks API DELETE requests require a
# non-empty Content-Type header, and an empty one is injected by the
# httpc adapter. This overrides the method for DELETE to force a valid
# content type, and passes through non-DELETE requests.
# This can be removed after https://bugs.erlang.org/browse/ERL-536 lands in a
# stable Erlang release.
defmodule ForceEmptyBodyAndContentTypeForDelete do
  def call(%{method: :delete, body: nil} = env, next, _opts) do
    env = %{env | body: "", headers: Map.put(env.headers, "Content-Type", "text/plain")}
    Tesla.run(env, next)
  end
  def call(env, next, _opts), do: Tesla.run(env, next)
end
