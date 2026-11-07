defmodule SopaReporte do
  @moduledoc """
  Módulo encargado de generar el archivo de texto con los resultados finales.
  Se asegura de escribir línea por línea para no saturar la memoria,
  cumpliendo con la regla de escritura del parcial.
  """

  @doc """
  Crea o reemplaza el archivo de salida y coordina la escritura de los resultados.
  Anota qué palabras se encontraron, de qué forma, o explica por qué fueron descartadas.
  """
  def generar_reporte(sopa, palabras, total_filas, total_columnas, archivo_salida) do
    # Abrimos el archivo listo para escribir
    {:ok, file} = File.open(archivo_salida, [:write, :utf8])

    # Contamos las letras del tablero una sola vez para usarlas en las validaciones
    letras_sopa = contar_letras_sopa_recursivo(Map.values(sopa), %{})

    # Procesamos las palabras una a una y llevamos la cuenta de cuántas encontramos
    {encontradas, total} = procesar_palabras(palabras, sopa, letras_sopa, total_filas, total_columnas, file, 0, 0)

    # Escribimos el resumen final y cerramos el archivo
    IO.write(file, "\nPalabras encontradas: #{encontradas} de #{total}\n")
    File.close(file)

    IO.puts("¡Búsqueda finalizada! Resultados escritos en #{archivo_salida}")
  end

  # --- Procesamiento de cada palabra ---

  # Cuando ya no hay más palabras, devolvemos los totales
  defp procesar_palabras([], _sopa, _letras_sopa, _tf, _tc, _file, encontradas, total), do: {encontradas, total}

  defp procesar_palabras([palabra | resto_palabras], sopa, letras_sopa, tf, tc, file, encontradas, total) do
    IO.write(file, "Palabra: #{palabra}\n")

    # 1. Verificamos si vale la pena buscarla (si están las letras)
    if SopaRecursion.palabra_posible?(palabra, letras_sopa) do

      # 2. Si están las letras, hacemos la búsqueda real en el tablero
      rutas = SopaRecursion.buscar_todas(sopa, tf, tc, palabra)

      if rutas == [] do
        # Estaban las letras revueltas, pero no formaban la palabra en línea recta
        IO.write(file, "Encontrada: No (estaban las letras pero no formaban la palabra)\n\n")
        procesar_palabras(resto_palabras, sopa, letras_sopa, tf, tc, file, encontradas, total + 1)
      else
        # ¡La encontramos! Anotamos de cuántas formas distintas
        cantidad_formas = longitud_lista(rutas, 0)
        plural = if cantidad_formas == 1, do: "forma", else: "formas"
        IO.write(file, "Encontrada: Sí (#{cantidad_formas} #{plural})\n")

        escribir_rutas(rutas, 1, file)
        IO.write(file, "\n")

        procesar_palabras(resto_palabras, sopa, letras_sopa, tf, tc, file, encontradas + 1, total + 1)
      end
    else
      # Se descartó desde el inicio, averiguamos qué letras faltaron para el reporte
      letras_faltantes = identificar_faltantes(palabra, letras_sopa)
      IO.write(file, "Encontrada: No (descartada: la sopa no tiene #{letras_faltantes})\n\n")
      procesar_palabras(resto_palabras, sopa, letras_sopa, tf, tc, file, encontradas, total + 1)
    end
  end

  # --- Escritura de las coordenadas ---

  # Escribe el detalle de cada ruta (dónde empieza, dónde termina y qué camino toma)
  defp escribir_rutas([], _indice, _file), do: :ok
  defp escribir_rutas([ruta | resto_rutas], indice, file) do
    inicio = hd(ruta)
    final = hd(Enum.reverse(ruta))
    direccion = calcular_direccion(ruta)

    IO.write(file, "Forma #{indice}: comienza en {#{elem(inicio, 0)},#{elem(inicio, 1)}}, termina en {#{elem(final, 0)},#{elem(final, 1)}}, dirección #{direccion}\n")

    # Dibuja la ruta con flechitas
    ruta_formateada = Enum.map_join(ruta, " -> ", fn {f, c} -> "{#{f},#{c}}" end)
    IO.write(file, "#{ruta_formateada}\n")

    escribir_rutas(resto_rutas, indice + 1, file)
  end

  # --- Funciones de ayuda ---

  # Adivina en qué dirección se leyó la palabra restando sus coordenadas
  defp calcular_direccion([_una_sola_letra]), do: "ninguna"
  defp calcular_direccion([{f1, c1}, {f2, c2} | _]) do
    case {f2 - f1, c2 - c1} do
      {0, 1} -> "derecha"
      {0, -1} -> "izquierda"
      {1, 0} -> "abajo"
      {-1, 0} -> "arriba"
      {1, 1} -> "abajo-derecha"
      {1, -1} -> "abajo-izquierda"
      {-1, 1} -> "arriba-derecha"
      {-1, -1} -> "arriba-izquierda"
      _ -> "desconocida"
    end
  end

  # Revisa qué letras exactas hicieron que la palabra se descartara
  defp identificar_faltantes(palabra, letras_sopa) do
    freqs = Enum.frequencies(String.graphemes(palabra))
    freqs
    |> Enum.filter(fn {letra, cant_nec} -> cant_nec > Map.get(letras_sopa, letra, 0) end)
    |> Enum.map(fn {letra, _} -> letra end)
    |> Enum.join(", ")
  end

  # Cuenta letras usando recursividad para mantener el estilo
  defp contar_letras_sopa_recursivo([], mapa), do: mapa
  defp contar_letras_sopa_recursivo([letra | resto], mapa) do
    contar_letras_sopa_recursivo(resto, Map.update(mapa, letra, 1, &(&1 + 1)))
  end

  # Cuenta cuántos elementos tiene una lista de forma recursiva
  defp longitud_lista([], acc), do: acc
  defp longitud_lista([_ | resto], acc), do: longitud_lista(resto, acc + 1)
end
