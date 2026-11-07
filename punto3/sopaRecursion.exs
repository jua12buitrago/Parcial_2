defmodule SopaRecursion do
  @moduledoc """
  Módulo que contiene la lógica central del juego usando exclusivamente recursividad.
  Aquí nos aseguramos de no usar herramientas automáticas como Enum o Stream para
  cumplir con las reglas del ejercicio.
  """

  @direcciones [
    {0, 1},   # Derecha
    {0, -1},  # Izquierda
    {1, 0},   # Abajo
    {-1, 0},  # Arriba
    {1, 1},   # Abajo-derecha
    {1, -1},  # Abajo-izquierda
    {-1, 1},  # Arriba-derecha
    {-1, -1}  # Arriba-izquierda
  ]

  @doc """
  Revisa si la sopa tiene las letras suficientes para formar la palabra.
  Si faltan letras, la descarta de inmediato para no perder tiempo buscando.
  """
  def palabra_posible?(palabra, letras_sopa) do
    frecuencias_palabra = contar_letras_recursivo(String.graphemes(palabra), %{})
    comparar_frecuencias(Map.keys(frecuencias_palabra), frecuencias_palabra, letras_sopa)
  end

  # Cuenta cuántas veces aparece cada letra en la palabra (recursivo)
  defp contar_letras_recursivo([], mapa_frecuencias), do: mapa_frecuencias
  defp contar_letras_recursivo([letra | resto], mapa_frecuencias) do
    nuevo_mapa = Map.update(mapa_frecuencias, letra, 1, &(&1 + 1))
    contar_letras_recursivo(resto, nuevo_mapa)
  end

  # Compara si las letras que necesitamos alcanzan con las que hay (recursivo)
  defp comparar_frecuencias([], _req, _disp), do: true
  defp comparar_frecuencias([letra | resto_letras], req, disp) do
    necesarias = Map.get(req, letra, 0)
    disponibles = Map.get(disp, letra, 0)

    if necesarias <= disponibles do
      comparar_frecuencias(resto_letras, req, disp)
    else
      false
    end
  end

  @doc """
  Inicia el recorrido manual por todo el tablero (fila por fila, columna por columna)
  para buscar la palabra en las 8 direcciones. Devuelve una lista con las rutas encontradas.
  """
  def buscar_todas(sopa, total_filas, total_columnas, palabra) do
    letras = String.graphemes(palabra)
    recorrer_filas(0, total_filas, total_columnas, sopa, letras, [])
  end

  # --- Recorrido manual de la matriz ---

  # Cuando ya no hay más filas, entregamos los resultados
  defp recorrer_filas(fila, total_filas, _cols, _sopa, _palabra, resultados)
       when fila >= total_filas, do: resultados

  defp recorrer_filas(fila, total_filas, total_columnas, sopa, palabra, resultados) do
    resultados_fila = recorrer_columnas(fila, 0, total_columnas, sopa, palabra, [])
    recorrer_filas(fila + 1, total_filas, total_columnas, sopa, palabra, concatenar_listas(resultados, resultados_fila))
  end

  # Cuando ya no hay más columnas en esta fila, entregamos los resultados de la fila
  defp recorrer_columnas(_fila, col, total_columnas, _sopa, _palabra, resultados)
       when col >= total_columnas, do: resultados

  defp recorrer_columnas(fila, col, total_columnas, sopa, palabra, resultados) do
    resultados_celda = probar_direcciones(@direcciones, fila, col, sopa, palabra, [])
    recorrer_columnas(fila, col + 1, total_columnas, sopa, palabra, concatenar_listas(resultados, resultados_celda))
  end

  # Cuando ya probamos las 8 direcciones en una coordenada específica
  defp probar_direcciones([], _f, _c, _sopa, _palabra, resultados), do: resultados

  defp probar_direcciones([{df, dc} | resto_dir], f, c, sopa, palabra, resultados) do
    case comparar_letras(f, c, df, dc, sopa, palabra, []) do
      nil ->
        probar_direcciones(resto_dir, f, c, sopa, palabra, resultados)
      ruta ->
        probar_direcciones(resto_dir, f, c, sopa, palabra, [revertir_lista(ruta, []) | resultados])
    end
  end

  # --- Comparación letra por letra ---

  # Si ya no quedan letras por buscar, significa que encontramos la palabra completa
  defp comparar_letras(_f, _c, _df, _dc, _sopa, [], ruta), do: ruta

  defp comparar_letras(f, c, df, dc, sopa, [letra_buscada | resto_palabra], ruta) do
    case Map.get(sopa, {f, c}) do
      ^letra_buscada ->
        # La letra coincide, seguimos buscando la siguiente en la misma dirección
        comparar_letras(f + df, c + dc, df, dc, sopa, resto_palabra, [{f, c} | ruta])
      _ ->
        # No coincide o nos salimos del tablero
        nil
    end
  end

  # --- Funciones de apoyo hechas a mano ---

  # Une dos listas sin usar herramientas automáticas
  defp concatenar_listas([], lista2), do: lista2
  defp concatenar_listas([cabeza | cola], lista2), do: [cabeza | concatenar_listas(cola, lista2)]

  # Voltea una lista al revés sin usar herramientas automáticas
  defp revertir_lista([], acumulador), do: acumulador
  defp revertir_lista([cabeza | cola], acumulador), do: revertir_lista(cola, [cabeza | acumulador])
end
