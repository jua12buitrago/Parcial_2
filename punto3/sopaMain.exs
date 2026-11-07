# Cargamos los otros archivos para que este módulo principal pueda usarlos
Code.require_file("sopaArchivos.exs")
Code.require_file("sopaRecursion.exs")
Code.require_file("sopaReporte.exs")

defmodule SopaMain do
  @moduledoc """
  Módulo principal que coordina todo el programa.
  Sirve como puente entre la lectura de archivos, la búsqueda de palabras y el reporte final.
  """

  @doc """
  Función que arranca todo el proceso.
  Lee los archivos, calcula de qué tamaño es la sopa de letras, nos muestra un
  pequeño resumen en pantalla y, si todo está bien, manda a crear el reporte con los resultados.
  """
  def ejecutar_problema3 do
    IO.puts("Iniciando ejecución...")

    ruta_sopa = "sopa.txt"
    ruta_palabras = "palabras.txt"
    archivo_salida = "resultado_sopa.txt"

    sopa = SopaArchivos.leer_sopa(ruta_sopa)
    IO.inspect(map_size(sopa), label: "Cantidad de letras leídas en la sopa")

    palabras = SopaArchivos.leer_palabras(ruta_palabras)
    IO.inspect(palabras, label: "Palabras a buscar")

    total_filas = si_vacio(Enum.map(Map.keys(sopa), &elem(&1, 0)), 0) + 1
    total_cols = si_vacio(Enum.map(Map.keys(sopa), &elem(&1, 1)), 0) + 1
    IO.inspect({total_filas, total_cols}, label: "Dimensiones de la matriz {filas, columnas}")

    if map_size(sopa) > 0 and palabras != [] do
      IO.puts("Datos válidos, generando reporte...")
      SopaReporte.generar_reporte(sopa, palabras, total_filas, total_cols, archivo_salida)
    else
      IO.puts(
        "ADVERTENCIA: No se pudo generar el reporte. La sopa está vacía o no hay palabras válidas."
      )
    end
  end

  # Función de ayuda para calcular el tamaño de la sopa sin que el programa falle si está vacía
  defp si_vacio([], default), do: default
  defp si_vacio(lista, _default), do: Enum.max(lista)
end

# Da la orden de iniciar el programa en cuanto se corre este archivo
SopaMain.ejecutar_problema3()
