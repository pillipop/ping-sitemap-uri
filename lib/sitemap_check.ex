defmodule SitemapCheck do
  @moduledoc """
  Documentation for `SitemapCheck`.
  """

  @doc """
  This is something quick and dirty, I know how xml looks like that's why this cleanup looks like this.
  """
  def read_and_parse_xml(path) when is_binary(path) do
    %{body: content} = HTTPoison.get!(path)

    case remove_xml_declaration(content) do
      {:ok, [data]} ->
        data
        |> unpack_xml()
        |> Enum.map(&enum_data/1)
        |> Enum.map(&ping/1)
        |> Enum.map(&resp_clean/1)
        # Nothing to see here \__(-^-)__/
        |> List.flatten
        |> Enum.filter(&filter_resp/1)
        |> IO.inspect([limit: :infinity, pretty: true])

      {:error, reason} ->
        IO.puts("Error removing XML declaration: #{reason}")
    end
  end

  defp remove_xml_declaration(content) do
    case String.split(content, "\n", parts: 2) do
      [_h | data] ->
        {:ok, data}
      _ ->
        {:error, "XML declaration not found"}
    end
  end

  defp ping(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} ->
        {:ok, {200, url, ""}}
      {:ok, %HTTPoison.Response{status_code: 301, body: body}} ->
        {:ok, {301, url, body}}
      {:ok, %HTTPoison.Response{status_code: 302, body: _body}} ->
        {:ok, {302, url, ""}}
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        {:ok, {404, url, body}}
      {:ok, %HTTPoison.Response{status_code: 500, body: _body}} ->
        {:ok, {500, url, ""}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {reason, "", ""}}
    end
  end

  defp enum_data(data) do
    {_, [], [uri]} = data
    uri
  end

  defp resp_clean(data) do
    {_x, y} = data
    y
  end

  defp filter_resp(data) do
    {x, _, _} = data
    if x == :timeout do
      "Timeout"
    else
      x != 200
    end
  end

  defp unpack_xml(data) do
    Floki.parse_document!(data)
    |> Floki.find("loc")
  end
end
