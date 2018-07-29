defmodule ProfitBricks do

  @moduledoc """
  Documentation for ProfitBricks.
  """

  use Tesla, only: [:head, :get, :post, :put, :patch, :delete]

  @api_endpoint_default "https://api.profitbricks.com/cloudapi/v4"

  if Application.get_env(:profitbricks_api_wrapper, :enable_tesla_log, false) do
    plug Tesla.Middleware.Logger
  end
  plug Tesla.Middleware.BaseUrl, Application.get_env(:profitbricks_api_wrapper, :api_endpoint, @api_endpoint_default)
  plug Tesla.Middleware.Headers, make_auth_header()
  plug Tesla.Middleware.JSON
  if Application.get_env(:profitbricks_api_wrapper, :http_retry_enabled, true) do
    plug Tesla.Middleware.Retry, delay: Application.get_env(:profitbricks_api_wrapper, :http_retry_delay, 1000), max_retries: Application.get_env(:profitbricks_api_wrapper, :http_retry_max_retries, 5)
  end
  if Application.get_env(:profitbricks_api_wrapper, :http_follow_redirects, true) do
    plug Tesla.Middleware.FollowRedirects
  end

  def make_auth_header() do
    [{"Authorization", "Basic " <> Base.encode64(Application.fetch_env!(:profitbricks_api_wrapper, :username) <> ":" <> Application.fetch_env!(:profitbricks_api_wrapper, :password))}]
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
