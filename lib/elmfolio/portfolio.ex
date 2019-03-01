defmodule Elmfolio.Portfolio do
  use HTTPoison.Base

  @headers ["content-type": "application/json"]
  @url "https://www.mocky.io/v2/5c7885cc300000780049ae90"
  @options [ssl: [{:versions, [:"tlsv1.2"]}], recv_timeout: 500]

  def list() do
    HTTPoison.get(@url, @headers, @options)
    |> handle_response()
  end

  defp handle_response({code, %HTTPoison.Response{body: responseBody}}) do
    {code, responseBody |> Jason.decode!()}
  end
end
