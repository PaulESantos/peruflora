# peruflora

`peruflora` consulta cuatro fuentes independientes de flora peruana: el
listado CITES de flora del MINAM (2018), los taxones endémicos aceptados
de `ppendemic` (WCVP V-16), el Libro Rojo de plantas endémicas (2006) y
el D. S. 043-2006-AG. Mantiene el estado, la edición y la incertidumbre
de cada fuente.

## Instalación

La primera versión de `peruflora` es 0.1.0. Hasta su publicación en
CRAN, instálela desde GitHub. Requiere `redbookperu` 0.1.0 o posterior,
disponible en CRAN:

``` r

if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
install.packages("redbookperu")
pak::pak("PaulESantos/peruflora")

packageVersion("redbookperu") # debe ser >= 0.1.0
```

Si ya tiene instalada una versión anterior de `redbookperu`, actualícela
desde CRAN antes de cargar `peruflora`. El adaptador usa
[`redbookperu::match_redbook_names()`](https://paulesantos.github.io/redbookperu/reference/match_redbook_names.html)
de la versión 0.1.0 y fija el parser `"legacy"` para mantener resultados
reproducibles con independencia de si `wcvpmatch` está instalado.

Los cuatro paquetes especializados también se pueden instalar y utilizar
por separado.
[`library(peruflora)`](https://github.com/PaulESantos/peruflora) los
adjunta en la sesión; sus funciones siguen disponibles con
`paquete::funcion()`. Al cargarse, `peruflora` muestra los paquetes
recién adjuntados con sus versiones y avisa si alguna función queda
enmascarada. Puede silenciar este aviso con
`suppressPackageStartupMessages(library(peruflora))` o con la opción
`options(peruflora.quiet = TRUE)`.

## Aplicación interactiva (Shiny)

`peruflora` incluye una aplicación interactiva Shiny opcional para
consultar, armonizar y auditar lotes de nombres científicos sin
necesidad de escribir código.

### Instalación de dependencias opcionales

``` r

install.packages(c("shiny", "DT", "callr", "later"))
# Opcional: para importación y descarga en Excel (.xlsx)
install.packages(c("readxl", "writexl"))
```

### Iniciar la aplicación

``` r

# Iniciar con el alias canónico
peruflora::flora_app()

# O con opciones avanzadas de host y puerto
peruflora::run_peruflora_app(host = "127.0.0.1", port = 3838)
```

También puedes ejecutarla directamente desde el archivo `app.R` en la
raíz del repositorio, o mediante:

``` r

shiny::runApp(system.file("app", package = "peruflora"))
```

### Capacidades principales

1.  **Ingesta flexible de datos**:
    - Pega nombres directamente en el área de texto o carga archivos en
      formatos **TXT**, **CSV** (con detección automática de comas o
      punto y coma de Excel en español), **TSV**, **XLS** o **XLSX**.
    - Reconocimiento automático de columnas taxonómicas
      (`scientific_name`, `nombre_cientifico`, `species`, `name`, etc.).
    - Admite hasta 10 000 nombres por lote con validación previa de
      caracteres y cardinalidad.
2.  **Cinco vistas especializadas**:
    - **Consulta integrada**: Ejecuta
      [`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
      (resumen) o
      [`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
      (evidencia detallada) cruzando simultáneamente las cuatro fuentes.
      Permite alternar entre modo *exploratorio* (con candidatos
      sugeridos) y modo *estricto*.
    - **CITES Flora**: Consulta los Apéndices I, II y III del listado
      oficial MINAM (2018), con parámetros configurables de distancia de
      edición, coincidencia por sinónimos o género.
    - **Endemismo actual**: Búsqueda jerárquica en el catálogo de
      plantas vasculares endémicas del Perú de `ppendemic` (basado en
      WCVP V-16, con más de 8000 registros).
    - **Libro Rojo**: Consulta contra el Libro Rojo de las Plantas
      Endémicas del Perú (León et al., 2006, `redbookperu`) con
      correspondencias taxonómicas actualizadas y categorías UICN
      técnicas.
    - **D.S. 043-2006-AG**: Verificación normativa de especies
      legalmente protegidas bajo el Decreto Supremo N° 043-2006-AG
      (`peruflorads43`), reconciliando taxonomía original y actualizada.
3.  **Ejecución asíncrona y cancelación**:
    - Las consultas se ejecutan en un subproceso en segundo plano
      (`callr` y `later`), manteniendo la interfaz responsiva y
      permitiendo cancelar la búsqueda en cualquier momento. Si el
      entorno no soporta procesos secundarios, conmuta automáticamente a
      modo síncrono.
4.  **Auditoría visual y métricas**:
    - Tarjetas KPI interactivas con recuentos y porcentajes de
      coincidencia por fuente.
    - Alerta visual destacada cuando existen filas que requieren
      revisión manual (`review_flag = TRUE`).
    - Tabla interactiva (`DT`) en español con ordenación, paginación y
      búsqueda facetada por columnas.
    - Ficha de detalle para inspeccionar exhaustivamente cualquier
      registro seleccionado.
5.  **Exportación reproducible**:
    - Descarga de resultados en formatos **CSV** (UTF-8) o **Excel
      (XLSX)**, preservando el archivo y número de fila de origen,
      estado de revisión y observaciones.

## Consulta integrada

``` r

library(peruflora)

nombres <- c("Swietenia macrophylla", "Aa aurantiaca",
             "Sanchezia ovata", "Cattleya maxima", "Persea americana")

evidencia <- flora_match(nombres)
evidencia
flora_status(evidencia)
```

[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md)
devuelve una fila por nombre y fuente. `evaluacion` distingue
`confirmado`, `sin_coincidencia`, `requiere_revision`, `ambiguo` y
`entrada_invalida`. `presencia = FALSE` significa ausencia **en la
edición consultada**. Los nombres aproximados se muestran en
`nombre_candidato` y su estado en `status_candidato`, sin trasladarlos a
`status_fuente`. El resumen
[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
muestra también esos estados candidatos y activa `requiere_revision`;
consulte el detalle antes de utilizarlos como confirmados.

``` r

flora_match("Catleya maxima", modo = "exploratorio")
flora_status(c("Aa aurantiaca", "Persea americana"))
flora_fuentes()
```

El modo `exploratorio` (predeterminado) permite sugerencias, siempre
marcadas para revisión. En modo `estricto`, CITES, WCVP y Libro Rojo
usan búsqueda exacta; la salida del D. S. 043 se comprueba además contra
el nombre ingresado porque su API no permite desactivar la búsqueda
aproximada. `sp.`, `spp.` y nombres de solo género quedan como
identificaciones incompletas.

Por ejemplo, `flora_status(c("Cattleya maxima", "Catleya maxima"))`
muestra el mismo apéndice CITES y la misma categoría D. S. 043 para
ambos nombres. Solo la segunda fila indica `requiere_revision = TRUE`;
los valores de esa fila son candidatos y se pueden auditar con
[`flora_match()`](https://paulesantos.github.io/peruflora/reference/flora_match.md).

## Evaluar un inventario

[`flora_status()`](https://paulesantos.github.io/peruflora/reference/flora_status.md)
acepta tablas con otras columnas si se indica `name_col`. El resultado
conserva una fila por registro, incluso cuando un nombre se repite.
`indice_entrada` corresponde a la posición de cada fila del inventario,
por lo que permite unir el resumen sin mezclar registros repetidos.

``` r

library(peruflora)
library(dplyr)
library(tibble)

inventario <- tibble(
  indice_entrada = 1:5,
  parcela = c("P01", "P01", "P02", "P02", "P03"),
  nombre_cientifico = c(
    "Aa aurantiaca",
    "Cattleya maxima",
    "Persea americana",
    "Aa aurantiaca",  # registro repetido
    "Catleya maxima"  # posible error de escritura
  ),
  abundancia = c(2, 1, 4, 3, 1)
)
inventario

estado <- flora_status(
  inventario,
  name_col = "nombre_cientifico"
)
estado

inventario_evaluado <- inventario |>
  left_join(
    select(estado, -nombre_original),
    by = "indice_entrada"
  )

inventario_evaluado
```

La fila con `Catleya maxima` conserva las categorías sugeridas en el
resumen, pero `requiere_revision = TRUE` indica que son candidatas. Para
revisar la evidencia de ese registro, use
`flora_match(inventario, name_col = "nombre_cientifico")`.

## Paquetes y procedencia

| Paquete | Información consultada |
|----|----|
| `citesperu` | Solo flora, edición MINAM 2018; apéndice CITES |
| `ppendemic` | Endemismo de taxones aceptados, WCVP V-16 |
| `redbookperu` | Registro histórico del Libro Rojo de 2006 |
| `peruflorads43` | Categoría del D. S. 043-2006-AG, nombres originales y actualizados |

[`peruflora_deps()`](https://paulesantos.github.io/peruflora/reference/peruflora_deps.md),
[`peruflora_sitrep()`](https://paulesantos.github.io/peruflora/reference/peruflora_sitrep.md)
y
[`peruflora_conflicts()`](https://paulesantos.github.io/peruflora/reference/peruflora_conflicts.md)
ayudan a inspeccionar versiones y posibles conflictos en la sesión. Cite
también cada paquete y fuente que utilice en un análisis. El Libro Rojo,
la lista WCVP, el decreto y CITES responden preguntas distintas; el
resumen no los combina en una categoría única de conservación.
