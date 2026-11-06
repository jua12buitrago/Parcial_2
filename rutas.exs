defmodule Conexion do
  @moduledoc """
  Representa una conexión entre dos ciudades y su distancia en kilómetros.

  Autor: Juan Manuel Castaño Buitrago-Samuel Mejia-Christian David Lopera
  Fecha: Noviembre del 2026
  """

  @enforce_keys [:origen, :destino, :distancia]
  defstruct [:origen, :destino, :distancia]

  @doc """
  Recibe una línea de texto en formato CSV y la convierte en un struct `%Conexion{}`.

  ## Parámetros
    - `linea`: Cadena de texto con los datos (`"Origen,Destino,Distancia"`).

  ## Retorno
    - `{:ok, %Conexion{}}` si la línea es válida y la distancia es un entero no negativo.
    - `{:error, motivo}` si faltan campos, la distancia es negativa o no es numérica.
  """
  def parse(linea) do
    linea_limpia = String.trim(linea)
    partes = String.split(linea_limpia, ",")
    partes_limpias = Enum.map(partes, fn p -> String.trim(p) end)

    case partes_limpias do
      [origen, destino, dist_str] ->
        if origen == "" or destino == "" do
          {:error, "Ciudad de origen o destino vacía"}
        else
          case Integer.parse(dist_str) do
            {distancia, ""} when distancia >= 0 ->
              {:ok, %Conexion{origen: origen, destino: destino, distancia: distancia}}

            {_dist, ""} ->
              {:error, "La distancia no puede ser negativa ('#{dist_str}')"}

            :error ->
              {:error, "Distancia no numérica ('#{dist_str}')"}
          end
        end

      _ ->
        {:error, "Formato incorrecto (se esperaban 3 campos)"}
    end
  end
end

defmodule Ruta do
  @moduledoc """
  Representa un camino completo encontrado entre dos ciudades dentro del grafo.

  Autor: Juan Manuel Castaño Buitrago-Samuel Mejia-Christian David Lopera
  Fecha: noviembre del 2026
  """

  @enforce_keys [:ciudades, :distancia]
  defstruct [:ciudades, :distancia]

  @doc """
  Genera la representación en cadena de texto formateada para mostrar en consola y guardar en archivo.

  ## Parámetros
    - `ruta`: Struct `%Ruta{}` a formatear.
    - `num_ruta`: Número secuencial asignado a la ruta.

  ## Retorno
    - Cadena de texto formateada con la secuencia de ciudades y distancia total.
  """
  def formatear(%Ruta{ciudades: ciudades, distancia: distancia}, num_ruta) do
    camino = Enum.join(ciudades, " -> ")
    num_ciudades = length(ciudades)
    "Ruta #{num_ruta}: #{camino} (#{num_ciudades} ciudades, #{distancia} km)"
  end
end

# MÓDULO DE DEPURACIÓN RECURSIVA

defmodule DepuradorConexiones do
  @moduledoc """
  Proporciona la funcionalidad para filtrar y depurar la lista de conexiones
  recorriéndola mediante recursión pura de cola sobre listas `[head | tail]`.

  Autor: Juan Manuel Castaño Buitrago-Samuel Mejia-Christian David Lopera
  Fecha: noviembre del 2026
  """

  @doc """
  Filtra una lista de conexiones aplicando las reglas de validación (conexión a sí misma,
  conexiones repetidas y distancias incongruentes).

  ## Parámetros
    - `lista_conexiones`: Lista de tuplas `{%Conexion{}, num_linea, texto_original}`.
    - `file_dep`: Descriptor de archivo abierto en modo escritura para registrar los descartes.

  ## Retorno
    - Tupla `{conexiones_filtradas, total_descartadas}`.
  """
  def depurar(lista_conexiones, file_dep) do
    do_depurar(lista_conexiones, [], 0, file_dep)
  end

  # Funciones privadas: La guía prohíbe el uso de @doc en funciones privadas (defp).
  # Se explica su lógica mediante comentarios de línea (#).

  # Caso base de la depuración recursiva: cuando la lista de entrada está vacía,
  # invierte el acumulador para mantener el orden original y devuelve el conteo.
  defp do_depurar([], acumulador, total_descartadas, _file_dep) do
    {invertir(acumulador, []), total_descartadas}
  end

  # Caso recursivo de depuración: evalúa cada elemento contra las tres reglas de descarte.
  defp do_depurar([{conexion, num_linea, texto_orig} | cola], acumulador, descartadas, file_dep) do
    c1 = conexion.origen
    c2 = conexion.destino
    dist = conexion.distancia

    cond do
      # Regla 1: Descartar conexiones de una ciudad consigo misma
      c1 == c2 ->
        IO.write(
          file_dep,
          "Línea #{num_linea}: #{texto_orig} -> conecta una ciudad consigo misma; se descarta\n"
        )

        do_depurar(cola, acumulador, descartadas + 1, file_dep)

      # Regla 2: Descartar conexiones repetidas exactas o inversas
      ya_existe_conexion?(c1, c2, dist, acumulador) ->
        linea_previa = buscar_linea_previa(c1, c2, acumulador)

        IO.write(
          file_dep,
          "Línea #{num_linea}: #{texto_orig} -> repetida (línea #{linea_previa}); se descarta\n"
        )

        do_depurar(cola, acumulador, descartadas + 1, file_dep)

      # Regla 3: Descartar par repetido con distinta distancia (se conserva la primera registrada)
      ya_existe_par_distinto?(c1, c2, dist, acumulador) ->
        {dist_prev, linea_prev} = buscar_distancia_y_linea(c1, c2, acumulador)

        IO.write(
          file_dep,
          "Línea #{num_linea}: #{texto_orig} -> distancia distinta a la de la línea #{linea_prev} (#{dist_prev}); se conserva la de la línea #{linea_prev}\n"
        )

        do_depurar(cola, acumulador, descartadas + 1, file_dep)

      # Conexión válida: conservar en el acumulador
      true ->
        do_depurar(cola, [{conexion, num_linea, texto_orig} | acumulador], descartadas, file_dep)
    end
  end

  # Función auxiliar recursiva de cola para invertir listas de forma eficiente.
  defp invertir([], acc), do: acc
  defp invertir([elem | cola], acc), do: invertir(cola, [elem | acc])

  # Verifica recursivamente si ya existe una conexión idéntica en el acumulador.
  defp ya_existe_conexion?(_c1, _c2, _dist, []), do: false

  defp ya_existe_conexion?(c1, c2, dist, [{conexion, _num, _txt} | cola]) do
    if ((c1 == conexion.origen and c2 == conexion.destino) or
          (c1 == conexion.destino and c2 == conexion.origen)) and dist == conexion.distancia do
      true
    else
      ya_existe_conexion?(c1, c2, dist, cola)
    end
  end

  # Verifica recursivamente si el mismo par de ciudades existe pero con diferente distancia.
  defp ya_existe_par_distinto?(_c1, _c2, _dist, []), do: false

  defp ya_existe_par_distinto?(c1, c2, dist, [{conexion, _num, _txt} | cola]) do
    if ((c1 == conexion.origen and c2 == conexion.destino) or
          (c1 == conexion.destino and c2 == conexion.origen)) and dist != conexion.distancia do
      true
    else
      ya_existe_par_distinto?(c1, c2, dist, cola)
    end
  end

  # Busca y retorna el número de línea previo donde se registró una conexión entre dos ciudades.
  defp buscar_linea_previa(c1, c2, [{conexion, num, _txt} | cola]) do
    if (c1 == conexion.origen and c2 == conexion.destino) or
         (c1 == conexion.destino and c2 == conexion.origen) do
      num
    else
      buscar_linea_previa(c1, c2, cola)
    end
  end

  # Busca y retorna la distancia y el número de línea previo de una conexión registrada.
  defp buscar_distancia_y_linea(c1, c2, [{conexion, num, _txt} | cola]) do
    if (c1 == conexion.origen and c2 == conexion.destino) or
         (c1 == conexion.destino and c2 == conexion.origen) do
      {conexion.distancia, num}
    else
      buscar_distancia_y_linea(c1, c2, cola)
    end
  end
end

# MÓDULO PRINCIPAL DE LA APLICACIÓN

defmodule RutasApp do
  @moduledoc """
  Módulo principal del sistema de rutas. Coordina la lectura perezosa de archivos con Streams,
  la construcción del grafo de ciudades, el cálculo del alcance mediante Streams infinitos,
  la búsqueda recursiva de rutas y la interacción con el usuario por consola.

  Autor: Juan Manuel Castaño Buitrago-Samuel Mejia-Christian David Lopera
  Fecha: Noviembre del 2026
  """

  @doc """
  Lee un archivo de forma perezosa con `File.stream!/1`, descartando líneas vacías y comentarios (`#`).

  ## Parámetros
    - `ruta_archivo`: Nombre o ruta del archivo de texto a leer.

  ## Retorno
    - Stream perezoso que emite tuplas `{linea_limpia, numero_de_linea}`.
  """
  def leer_lineas_utiles(ruta_archivo) do
    File.stream!(ruta_archivo)
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, num} -> {String.trim(linea), num} end)
    |> Stream.reject(fn {linea, _num} ->
      linea == "" or String.starts_with?(linea, "#")
    end)
  end

  @doc """
  Procesa el archivo CSV de conexiones de manera perezosa y registra los errores sintácticos.

  ## Parámetros
    - `archivo_csv`: Nombre del archivo CSV de conexiones de entrada.
    - `archivo_errores`: Archivo de salida para reportar errores de formato.

  ## Retorno
    - Tupla `{conexiones_validas, total_errores_formato}`.
  """
  def cargar_conexiones(archivo_csv, archivo_errores) do
    file_err = File.open!(archivo_errores, [:write, :utf8])

    {conexiones_validas, total_errores} =
      leer_lineas_utiles(archivo_csv)
      |> Enum.reduce({[], 0}, fn {linea, num}, {acc_validas, acc_errores} ->
        case Conexion.parse(linea) do
          {:ok, conexion} ->
            {[{:ok_conexion, conexion, num, linea} | acc_validas], acc_errores}

          {:error, motivo} ->
            IO.write(file_err, "Línea #{num}: #{linea} -> #{motivo}\n")
            {acc_validas, acc_errores + 1}
        end
      end)

    File.close(file_err)

    {Enum.reverse(conexiones_validas), total_errores}
  end

  @doc """
  Construye un mapa que representa el grafo no dirigido de ciudades a partir de la lista de conexiones.

  ## Parámetros
    - `conexiones_depuradas`: Lista de structs `%Conexion{}` válidos.

  ## Retorno
    - Mapa donde la clave es el nombre de la ciudad y el valor es la lista de tuplas `{"Vecino", distancia}`.
  """
  def construir_grafo(conexiones_depuradas) do
    Enum.reduce(conexiones_depuradas, %{}, fn %Conexion{origen: o, destino: d, distancia: dist}, acc ->
      acc
      |> Map.update(o, [{d, dist}], fn lista -> [{d, dist} | lista] end)
      |> Map.update(d, [{o, dist}], fn lista -> [{o, dist} | lista] end)
    end)
  end

  @doc """
  Solicita al usuario una entrada por teclado y valida recursivamente que no sea una cadena vacía.

  ## Parámetros
    - `prompt`: Mensaje a mostrar en pantalla solicitando el dato.
    - `nombre_campo`: Nombre del campo para personalizar el mensaje de error.

  ## Retorno
    - Cadena de texto no vacía ingresada por el usuario.
  """
  def pedir_campo(prompt, nombre_campo) do
    valor = IO.gets(prompt) |> String.trim()

    if valor == "" do
      IO.puts("Error: Ingrese el #{nombre_campo} (campo obligatorio).")
      pedir_campo(prompt, nombre_campo)
    else
      valor
    end
  end

  @doc """
  Busca en el grafo el nombre exacto de una ciudad ignorando diferencias entre mayúsculas y minúsculas.

  ## Parámetros
    - `ciudad_input`: Texto ingresado por el usuario.
    - `grafo`: Mapa del grafo de ciudades.

  ## Retorno
    - Nombre de la ciudad con su capitalización exacta registrada en el grafo, o `nil` si no existe.
  """
  def buscar_ciudad_en_grafo(ciudad_input, grafo) do
    ciudades = Map.keys(grafo)
    ciudad_minus = String.downcase(ciudad_input)

    Enum.find(ciudades, fn c -> String.downcase(c) == ciudad_minus end)
  end

  @doc """
  Calcula el alcance progresivo de ciudades partiendo de un origen usando un Stream infinito y `Stream.transform/3`.

  ## Parámetros
    - `origen`: Ciudad inicial para explorar el alcance.
    - `grafo`: Mapa con las conexiones entre ciudades.

  ## Retorno
    - Stream perezoso que emite conjuntos `MapSet` con las ciudades alcanzables en cada paso hasta la estabilización.
  """
  def calcular_alcance(origen, grafo) do
    Stream.iterate({MapSet.new([origen]), 0}, fn {visitados, _paso} ->
      nuevos =
        Enum.reduce(visitados, visitados, fn ciudad, acc ->
          vecinos = Map.get(grafo, ciudad, []) |> Enum.map(fn {v, _d} -> v end)
          MapSet.union(acc, MapSet.new(vecinos))
        end)

      {nuevos, 1}
    end)
    |> Stream.transform(MapSet.new(), fn {conjunto, _}, acumulado_previo ->
      if conjunto == acumulado_previo do
        {:halt, conjunto}
      else
        {[conjunto], conjunto}
      end
    end)
  end

  @doc """
  Escribe el historial de pasos del alcance en el archivo `alcance.txt`.

  ## Parámetros
    - `origen`: Ciudad desde la que se inició el cálculo.
    - `pasos_alcance`: Lista de conjuntos `MapSet` de cada paso.
    - `file_alcance`: Descriptor de archivo abierto en modo escritura.

  ## Retorno
    - `MapSet` final con todas las ciudades alcanzables.
  """
  def guardar_alcance(origen, pasos_alcance, file_alcance) do
    IO.write(file_alcance, "=== Alcance desde #{origen} ===\n")

    pasos_alcance
    |> Enum.with_index()
    |> Enum.each(fn {paso, i} ->
      ciudades = paso |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")
      linea = "Paso #{i}: #{ciudades}\n"
      IO.write(file_alcance, linea)
    end)

    num_paso_estab = length(pasos_alcance) - 1
    total_pasos = length(pasos_alcance)

    linea_estab =
      "Total de pasos de alcance: #{total_pasos} (se estabiliza en el paso #{num_paso_estab})\n\n"

    IO.write(file_alcance, linea_estab)

    List.last(pasos_alcance)
  end

  @doc """
  Inicia la búsqueda recursiva de todos los caminos posibles entre una ciudad de origen y una de destino.

  ## Parámetros
    - `origen`: Ciudad inicial.
    - `destino`: Ciudad de llegada.
    - `grafo`: Mapa del grafo.

  ## Retorno
    - Lista de structs `%Ruta{}` encontrados.
  """
  def buscar_rutas(origen, destino, grafo) do
    do_buscar_rutas(origen, destino, grafo, [origen], 0)
  end

  # Función privada recursiva para explorar rutas en profundidad (DFS) evitando ciclos.
  defp do_buscar_rutas(actual, destino, _grafo, camino, dist) when actual == destino do
    [%Ruta{ciudades: Enum.reverse(camino), distancia: dist}]
  end

  defp do_buscar_rutas(actual, destino, grafo, camino, dist) do
    vecinos = Map.get(grafo, actual, [])

    Enum.flat_map(vecinos, fn {vecino, dist_tramo} ->
      if vecino in camino do
        []
      else
        do_buscar_rutas(vecino, destino, grafo, [vecino | camino], dist + dist_tramo)
      end
    end)
  end

  @doc """
  Evalúa y resuelve una consulta individual entre origen y destino, validando la existencia
  de las ciudades y guardando los resultados en consola y archivos de salida.

  ## Parámetros
    - `origen_input`: Texto ingresado para la ciudad de origen.
    - `destino_input`: Texto ingresado para la ciudad de destino.
    - `grafo`: Mapa del grafo.
    - `file_rutas`: Descriptor de archivo para `rutas_encontradas.txt`.
    - `file_alcance`: Descriptor de archivo para `alcance.txt`.
  """
  def resolver_consulta(origen_input, destino_input, grafo, file_rutas, file_alcance) do
    origen = buscar_ciudad_en_grafo(origen_input, grafo) || origen_input
    destino = buscar_ciudad_en_grafo(destino_input, grafo) || destino_input

    encabezado = "=== #{origen} -> #{destino} ===\n"
    IO.write(file_rutas, encabezado)
    IO.puts(encabezado)

    ciudades_registradas = Map.keys(grafo)

    cond do
      origen not in ciudades_registradas ->
        msg = "La ciudad de origen '#{origen}' no existe en el grafo.\n\n"
        IO.write(file_rutas, msg)
        IO.puts(msg)

      destino not in ciudades_registradas ->
        msg = "La ciudad de destino '#{destino}' no existe en el grafo.\n\n"
        IO.write(file_rutas, msg)
        IO.puts(msg)

      true ->
        pasos_alcance = calcular_alcance(origen, grafo) |> Enum.to_list()
        conjunto_final = guardar_alcance(origen, pasos_alcance, file_alcance)

        if MapSet.member?(conjunto_final, destino) do
          rutas_halladas = buscar_rutas(origen, destino, grafo)

          if rutas_halladas == [] do
            msg = "sin rutas\n\n"
            IO.write(file_rutas, msg)
            IO.puts(msg)
          else
            escribir_rutas(rutas_halladas, file_rutas)
          end
        else
          msg = "sin rutas (el destino no es alcanzable desde el origen)\n\n"
          IO.write(file_rutas, msg)
          IO.puts(msg)
        end
    end
  end

  # Escribe y muestra las rutas encontradas, calculando la más corta en ciudades y la de menor distancia en km.
  defp escribir_rutas(rutas, file_rutas) do
    rutas
    |> Enum.with_index(1)
    |> Enum.each(fn {ruta, i} ->
      linea = Ruta.formatear(ruta, i) <> "\n"
      IO.write(file_rutas, linea)
      IO.write(linea)
    end)

    num_rutas = length(rutas)
    l_total = "Número de rutas: #{num_rutas}\n"
    IO.write(file_rutas, l_total)
    IO.write(l_total)

    # Identificar ruta(s) más corta(s) (menor cantidad de ciudades visitadas)
    min_num_ciudades = rutas |> Enum.map(fn r -> length(r.ciudades) end) |> Enum.min()

    rutas_cortas =
      rutas
      |> Enum.filter(fn r -> length(r.ciudades) == min_num_ciudades end)
      |> Enum.map(fn r -> Enum.join(r.ciudades, " -> ") end)
      |> Enum.join(", ")

    l_corta = "Ruta más corta: #{rutas_cortas}\n"
    IO.write(file_rutas, l_corta)
    IO.write(l_corta)

    # Identificar ruta de menor distancia total en kilómetros
    ruta_menor_km = Enum.min_by(rutas, fn r -> r.distancia end)
    camino_menor = Enum.join(ruta_menor_km.ciudades, " -> ")
    l_menor = "Ruta de menor distancia: #{camino_menor} (#{ruta_menor_km.distancia} km)\n\n"

    IO.write(file_rutas, l_menor)
    IO.write(l_menor)
  end

  @doc """
  Punto de inicio de la aplicación. Coordina el flujo completo: verificación de archivos,
  parsing perezoso, depuración recursiva, construcción del grafo y atención interactiva.
  """
  def ejecutar do
    archivo_conexiones = "conexiones.csv"

    cond do
      not File.exists?(archivo_conexiones) ->
        IO.puts("Error: El archivo '#{archivo_conexiones}' no existe.")

      true ->
        # 1. Cargar conexiones sintácticamente válidas
        {raw_conexiones, total_errores} =
          cargar_conexiones(archivo_conexiones, "errores_conexiones.txt")

        # 2. Depuración lógica recursiva sobre conexiones válidas
        file_dep = File.open!("depuracion_conexiones.txt", [:write, :utf8])

        lista_para_depurar =
          Enum.map(raw_conexiones, fn {:ok_conexion, conexion, num, linea} ->
            {conexion, num, linea}
          end)

        {conexiones_depuradas, total_descartadas} =
          DepuradorConexiones.depurar(lista_para_depurar, file_dep)

        File.close(file_dep)

        # 3. Construir el grafo con conexiones completamente limpias
        conexiones_limpias =
          Enum.map(conexiones_depuradas, fn {conexion, _num, _txt} -> conexion end)

        grafo = construir_grafo(conexiones_limpias)

        # 4. Solicitud interactiva de ciudades
        IO.puts("\n=== CONSULTA DE RUTAS ENTRE CIUDADES ===")
        origen = pedir_campo("Ingrese la ciudad de origen: ", "origen")
        destino = pedir_campo("Ingrese la ciudad de destino: ", "destino")
        IO.puts("")

        # 5. Apertura de archivos de resultados y resolución de consulta
        file_rutas = File.open!("rutas_encontradas.txt", [:write, :utf8])
        file_alcance = File.open!("alcance.txt", [:write, :utf8])

        resolver_consulta(origen, destino, grafo, file_rutas, file_alcance)

        File.close(file_rutas)
        File.close(file_alcance)

        # 6. Resumen en consola de los datos procesados
        IO.puts("--- Resumen de Procesamiento ---")
        IO.puts("Total de errores de formato (errores_conexiones.txt): #{total_errores}")

        IO.puts(
          "Total de conexiones descartadas (depuracion_conexiones.txt): #{total_descartadas}"
        )

        IO.puts("Conexiones válidas integradas al grafo: #{length(conexiones_limpias)}")

        IO.puts(
          "\nConsulta finalizada con éxito. Resultados guardados en los archivos correspondientes."
        )
    end
  end
end

# Iniciar la ejecución del programa
RutasApp.ejecutar()
