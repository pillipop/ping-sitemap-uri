defmodule SitemapCheck do
  @moduledoc """
  Documentation for `SitemapCheck`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> SitemapCheck.hello()
      :world

  """
  def read_and_parse_xml(path) when is_binary(path) do
    %{body: content} = HTTPoison.get!(path)

    case remove_xml_declaration(content) do
      {:ok, [data]} ->
        data
        |> unpack_xml()
        |> Enum.map(&enum_data/1)
        |> Enum.map(&ping/1)
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
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        {:ok, {200, url}}
      {:ok, %HTTPoison.Response{status_code: 301, body: body}} ->
        {:ok, {301, url, body}}
      {:ok, %HTTPoison.Response{status_code: 302}} ->
        {:ok, {302, url}}
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        {:ok, {404, url, body}}
      {:ok, %HTTPoison.Response{status_code: 500}} ->
        {:ok, {500, url}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {reason}}
    end
  end

  defp enum_data(data) do
    {_, [], [uri]} = data
    uri
  end

  defp unpack_xml(data) do
    Floki.parse_document!(data)
    |> Floki.find("loc")
  end
end
