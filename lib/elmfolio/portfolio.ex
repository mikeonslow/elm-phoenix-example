defmodule Elmfolio.Portfolio.Api do
  use HTTPoison.Base

  @headers ["content-type": "application/json"]
  @url "https://www.mocky.io/v2/5c7885cc300000780049ae90"
  @options [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 500]

  def get() do
    HTTPoison.get(@url, @headers, @options)
    |> handle_response()
  end

  defp handle_response({_, %HTTPoison.Response{status_code: responseCode, body: responseBody}})
       when responseCode == 200 do
    {responseCode, responseBody |> Jason.decode!()}
  end

  defp handle_response({_, %HTTPoison.Response{status_code: responseCode}}) do
    {responseCode, struct(Elmfolio.Portfolio)}
  end
end

defmodule Elmfolio.Portfolio do
  @derive {Jason.Encoder, only: [:categories, :items]}
  defstruct categories: [], items: []
end
