defmodule SopaArchivos do
  @moduledoc """
  Módulo encargado de leer los archivos de texto necesarios para el juego.
  """

  @doc """
  Lee el archivo de la sopa de letras.
  Ignora las líneas vacías o comentarios y devuelve un mapa donde cada
  posición {fila, columna} tiene su letra correspondiente en mayúscula.
  """
  def leer_sopa(ruta_archivo) do
    if File.exists?(ruta_archivo) do
      ruta_archivo
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(fn linea -> linea == "" or String.starts_with?(linea, "#") end)
      |> Stream.with_index()
      |> Enum.reduce(%{}, fn {linea, fila}, mapa_acc ->
        linea
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.reduce(mapa_acc, fn {letra, columna}, mapa_fila ->
          Map.put(mapa_fila, {fila, columna}, String.upcase(letra))
        end)
      end)
    else
      IO.puts("Error: El archivo #{ruta_archivo} no existe.")
      %{}
    end
  end

  @doc """
  Lee el archivo con las palabras a buscar.
  Ignora las líneas vacías o comentarios, convierte todas las palabras a
  mayúsculas y elimina las que estén repetidas para entregar una lista limpia.
  """
  def leer_palabras(ruta_archivo) do
    if File.exists?(ruta_archivo) do
      ruta_archivo
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(fn linea -> linea == "" or String.starts_with?(linea, "#") end)
      |> Stream.map(&String.upcase/1)
      |> Enum.uniq()
    else
      IO.puts("Error: El archivo #{ruta_archivo} no existe.")
      []
    end
  end
end
