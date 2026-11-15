#' Fuentes integradas por `peruflora`
#'
#' Devuelve las ediciones consultadas por [flora_match()] y las versiones
#' instaladas de los paquetes. Describe fuentes locales, no su vigencia legal.
#' @return Tibble con fuente, paquete, edición, referencia y versión instalada.
#' @export
flora_fuentes <- function() {
  packages <- .flora_source_packages()
  meta <- lapply(names(packages), .flora_meta)
  tibble::tibble(
    fuente = names(packages), paquete = unname(packages),
    edicion = vapply(meta, `[[`, character(1), "edicion"),
    referencia = vapply(meta, `[[`, character(1), "referencia"),
    paquete_version = vapply(packages, .flora_version, character(1))
  )
}
