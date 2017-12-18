defmodule ProfitBricks do

  @moduledoc """
  Documentation for ProfitBricks.
  """

  @api_endpoint_default "https://api.profitbricks.com/cloudapi/v4"

  use Tesla, only: [:head, :get, :post, :put, :patch, :delete]

  @username Application.get_env(:profitbricks, :username)
  @password Application.get_env(:profitbricks, :password)

  plug Tesla.Middleware.BaseUrl, Application.get_env(:profitbricks, :api_endpoint, @api_endpoint_default)
  plug Tesla.Middleware.Headers, make_auth_header
  plug Tesla.Middleware.JSON
  if Application.get_env(:profitbricks, :debug_http) do
    plug Tesla.Middleware.DebugLogger
  end

  def make_auth_header() do
    %{"Authorization" => "Basic " <> Base.encode64(@username <> ":" <> @password)}
  end

  # Profitbricks API doesn't allow post requests that are supposed to have no
  # data to declare an application/json data content type. So here, build a
  # custom, single arg POST function that skips the content type.
  def post(path) do
    headers = Map.merge(make_auth_header, %{"Content-Type" => "application/x-www-form-urlencoded"})
    Tesla.post(@api_endpoint_default <> path, "", headers: headers)
  end

end
