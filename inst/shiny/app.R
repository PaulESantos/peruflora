# Entrypoint para peruflora Shiny app
# Uso: shiny::runApp(system.file("shiny", package = "peruflora"))
if (!requireNamespace("peruflora", quietly = TRUE)) {
  stop("El paquete 'peruflora' debe estar instalado.", call. = FALSE)
}

peruflora::peruflora_app()
