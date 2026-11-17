# Abrir la aplicación interactiva de peruflora

Consulta nombres científicos de plantas en cinco vistas: integrada,
CITES Flora, endemismo actual (WCVP), Libro Rojo de plantas endémicas y
categorías de amenaza del D.S. 043-2006-AG. La entrada puede pegarse o
importarse desde TXT, CSV, TSV, XLS o XLSX. Las búsquedas se ejecutan en
un proceso en segundo plano (con respaldo automático para ejecución
síncrona) y los resultados se pueden descargar en CSV o XLSX.

## Usage

``` r
run_peruflora_app(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive(),
  max_request_size = 20 * 1024^2,
  options = list()
)

flora_app(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive(),
  max_request_size = 20 * 1024^2,
  options = list()
)

peruflora_app(options = list())
```

## Arguments

- host:

  Interfaz de red para Shiny. Por defecto, solo el equipo local
  (`"127.0.0.1"`).

- port:

  Puerto. `NULL` permite que Shiny elija uno libre.

- launch.browser:

  Abrir el navegador al iniciar la aplicación.

- max_request_size:

  Tamaño máximo de carga de archivos en bytes. Por defecto, 20 MB.

- options:

  Lista de opciones pasadas a
  [`shiny::shinyApp`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

Devuelve de forma invisible el resultado de
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html). En
`peruflora_app()`, devuelve el objeto `shinyApp`.
