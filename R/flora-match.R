#' Consultar fuentes independientes de flora peruana
#'
#' `flora_match()` devuelve una fila por nombre y fuente. `presencia` afirma
#' inclusión únicamente en la edición consultada; una coincidencia aproximada
#' permanece como candidata hasta su revisión.
#'
#' @param x Vector de nombres (o factor) o tabla con una columna de nombres.
#' @param name_col Nombre de la columna cuando `x` es una tabla. Si se omite,
#'   se reconoce una columna usual o la única columna disponible.
#' @param fuentes Subconjunto de `"cites"`, `"endemismo_actual"`,
#'   `"libro_rojo"` y `"ds043"`.
#' @param modo `"exploratorio"` (predeterminado) o `"estricto"`. El modo
#'   exploratorio permite las distancias propias de cada paquete, pero no
#'   confirma automáticamente sus candidatos.
#' @return Tibble largo de evidencia. `status_fuente` contiene solo valores
#'   confirmados; `status_candidato` conserva valores pendientes de revisión.
#' @export
#' @examples
#' flora_match("Aa aurantiaca", fuentes = "cites")
flora_match <- function(x, name_col = NULL,
                        fuentes = c("cites", "endemismo_actual", "libro_rojo", "ds043"),
                        modo = c("exploratorio", "estricto")) {
  modo <- match.arg(modo)
  fuentes <- .flora_validate_sources(fuentes)
  names_in <- .flora_input(x, name_col)
  n <- length(names_in)
  if (!n) {
    result <- .flora_empty()
    class(result) <- c("flora_match_result", class(result))
    return(result)
  }

  valid <- !is.na(names_in) & nzchar(trimws(names_in))
  indeterminate <- valid & grepl("^[[:alpha:]][[:alpha:].-]*(?:[[:space:]]+(?:sp|spp)\\.?)?$",
                                 trimws(names_in), ignore.case = TRUE, perl = TRUE)
  positions <- which(valid & !indeterminate)
  queries <- names_in[positions]
  unique_queries <- unique(queries)
  versions <- vapply(.flora_source_packages()[fuentes], .flora_version, character(1))
  blocks <- vector("list", length(fuentes))

  for (j in seq_along(fuentes)) {
    source <- fuentes[j]
    block <- .flora_template(names_in, source, versions[j])
    if (any(indeterminate)) {
      block$evaluacion[indeterminate] <- "requiere_revision"
      block$tipo_coincidencia[indeterminate] <- "identificacion_incompleta"
    }
    if (length(positions)) {
      matched_unique <- tryCatch(
        switch(source,
          cites = .flora_cites(unique_queries, modo),
          endemismo_actual = .flora_endemic(unique_queries, modo),
          libro_rojo = .flora_redbook(unique_queries, modo),
          ds043 = .flora_ds43(unique_queries, modo)
        ),
        error = function(e) stop(sprintf("Fall\u00f3 la consulta a %s: %s", source,
                                  conditionMessage(e)), call. = FALSE)
      )
      matched <- matched_unique[match(queries, unique_queries), , drop = FALSE]
      .flora_check_result(matched, queries, source)
      block[positions, names(matched)] <- matched
    }
    blocks[[j]] <- block
  }
  result <- tibble::as_tibble(do.call(rbind, blocks))
  class(result) <- c("flora_match_result", class(result))
  result
}

.flora_source_packages <- function() {
  c(cites = "citesperu", endemismo_actual = "ppendemic",
    libro_rojo = "redbookperu", ds043 = "peruflorads43")
}

.flora_validate_sources <- function(x) {
  allowed <- names(.flora_source_packages())
  if (!is.character(x) || !length(x) || anyNA(x) ||
      any(!x %in% allowed) || anyDuplicated(x)) {
    stop("`fuentes` debe contener nombres \u00fanicos de: ",
         paste(allowed, collapse = ", "), ".", call. = FALSE)
  }
  x
}

.flora_input <- function(x, name_col) {
  if (is.data.frame(x)) {
    if (!is.null(name_col)) {
      if (!is.character(name_col) || length(name_col) != 1L ||
          is.na(name_col) || !name_col %in% names(x)) {
        stop("`name_col` debe nombrar una columna de `x`.", call. = FALSE)
      }
      col <- name_col
    } else {
      candidates <- c("scientific_name", "nombre_cientifico", "species_name",
                      "species", "taxon", "name", "splist")
      found <- match(candidates, tolower(names(x)), nomatch = 0L)
      found <- found[found > 0L]
      if (length(found)) col <- names(x)[found[1L]]
      else if (ncol(x) == 1L) col <- names(x)[1L]
      else stop("Indique `name_col` para identificar los nombres cient\u00edficos.",
                call. = FALSE)
    }
    x <- x[[col]]
  } else if (!is.null(name_col)) {
    stop("`name_col` solo se usa con tablas.", call. = FALSE)
  }
  if (!is.character(x) && !is.factor(x)) {
    stop("`x` debe ser un vector de texto, factor o tabla.", call. = FALSE)
  }
  as.character(x)
}

.flora_version <- function(pkg) {
  version <- utils::packageDescription(pkg, fields = "Version")
  if (length(version) != 1L || is.na(version)) {
    stop("No se pudo identificar la versi\u00f3n de ", pkg, ".", call. = FALSE)
  }
  version
}

.flora_empty <- function() {
  tibble::tibble(
    indice_entrada = integer(), nombre_original = character(),
    fuente = character(), edicion = character(), paquete_version = character(),
    nombre_coincidente = character(), nombre_aceptado = character(),
    nombre_candidato = character(), tipo_coincidencia = character(),
    evaluacion = character(), distancia = double(), presencia = logical(),
    status_fuente = character(), status_candidato = character(),
    id_registro = character(), referencia = character()
  )
}

.flora_template <- function(names_in, source, version) {
  n <- length(names_in)
  meta <- .flora_meta(source)
  tibble::tibble(
    indice_entrada = seq_len(n), nombre_original = names_in,
    fuente = rep(source, n), edicion = rep(meta$edicion, n),
    paquete_version = rep(version, n),
    nombre_coincidente = rep(NA_character_, n),
    nombre_aceptado = rep(NA_character_, n),
    nombre_candidato = rep(NA_character_, n),
    tipo_coincidencia = rep(NA_character_, n),
    evaluacion = ifelse(is.na(names_in) | !nzchar(trimws(names_in)),
                        "entrada_invalida", NA_character_),
    distancia = rep(NA_real_, n), presencia = rep(NA, n),
    status_fuente = rep(NA_character_, n),
    status_candidato = rep(NA_character_, n),
    id_registro = rep(NA_character_, n), referencia = rep(meta$referencia, n)
  )
}

.flora_meta <- function(source) {
  switch(source,
    cites = list(edicion = "MINAM flora 2018", referencia = "cites_flora_peru_2018"),
    endemismo_actual = list(edicion = "WCVP V-16 (2026-06-04)", referencia = "ppendemic_tab16"),
    libro_rojo = list(edicion = "Libro Rojo 2006", referencia = "redbook_sp_data"),
    ds043 = list(edicion = "D. S. 043-2006-AG", referencia = "original y nomenclatura actualizada")
  )
}

.flora_check_result <- function(x, names_in, source) {
  required <- c("nombre_coincidente", "nombre_aceptado", "nombre_candidato",
                "tipo_coincidencia", "evaluacion", "distancia", "presencia",
                "status_fuente", "status_candidato", "id_registro")
  if (!is.data.frame(x) || nrow(x) != length(names_in) ||
      !identical(names(x), required) ||
      anyNA(x$evaluacion) ||
      any(!x$evaluacion %in% c("confirmado", "requiere_revision", "ambiguo",
                              "sin_coincidencia", "entrada_invalida"))) {
    stop("El adaptador de ", source, " incumpli\u00f3 el contrato de resultados.",
         call. = FALSE)
  }
  expected <- x$evaluacion == "confirmado"
  uncertain <- x$evaluacion %in% c("requiere_revision", "ambiguo", "entrada_invalida")
  if (!identical(is.na(x$presencia), uncertain) ||
      any(x$presencia[expected] != TRUE) ||
      any(x$presencia[x$evaluacion == "sin_coincidencia"] != FALSE)) {
    stop("El adaptador de ", source, " devolvi\u00f3 una presencia incoherente.",
         call. = FALSE)
  }
  invisible(TRUE)
}

.flora_clean <- function(x) {
  x <- as.character(x)
  x[!is.na(x) & (x == "---" | !nzchar(trimws(x)))] <- NA_character_
  x
}

.flora_same <- function(a, b) {
  a <- .flora_clean(a)
  b <- .flora_clean(b)
  !is.na(a) & !is.na(b) &
    tolower(gsub("[[:space:]]+", " ", trimws(a))) ==
    tolower(gsub("[[:space:]]+", " ", trimws(b)))
}

.flora_result <- function(n) {
  data.frame(
    nombre_coincidente = rep(NA_character_, n),
    nombre_aceptado = rep(NA_character_, n),
    nombre_candidato = rep(NA_character_, n),
    tipo_coincidencia = rep(NA_character_, n),
    evaluacion = rep("sin_coincidencia", n),
    distancia = rep(NA_real_, n), presencia = rep(FALSE, n),
    status_fuente = rep(NA_character_, n),
    status_candidato = rep(NA_character_, n),
    id_registro = rep(NA_character_, n), stringsAsFactors = FALSE
  )
}

.flora_cites <- function(x, modo) {
  raw <- citesperu::cites_match(x, taxon = "flora", edition = "2018",
                               max_dist = if (modo == "estricto") 0L else 1L,
                               genus_fallback = FALSE, output = "standard")
  if (nrow(raw) != length(x) || !identical(as.integer(raw$input_index), seq_along(x))) {
    stop("CITES cambi\u00f3 el orden o n\u00famero de filas.", call. = FALSE)
  }
  out <- .flora_result(length(x))
  confirmed <- raw$match_assessment == "matched" & raw$match_type %in% c("exact", "synonym")
  review <- raw$match_assessment %in% c("requires_taxonomic_validation", "requires_species_validation")
  ambiguous <- raw$match_assessment == "ambiguous_match"
  out$evaluacion[confirmed] <- "confirmado"
  out$evaluacion[review] <- "requiere_revision"
  out$evaluacion[ambiguous] <- "ambiguo"
  out$presencia[confirmed] <- TRUE
  out$presencia[review | ambiguous] <- NA
  out$nombre_coincidente[confirmed] <- .flora_clean(raw$matched_name[confirmed])
  out$nombre_aceptado[confirmed] <- .flora_clean(raw$accepted_name[confirmed])
  out$nombre_candidato[review] <- .flora_clean(raw$accepted_name[review])
  out$tipo_coincidencia <- as.character(raw$match_type)
  out$distancia <- as.double(raw$matched_dist)
  out$status_fuente[confirmed] <- as.character(raw$apendice[confirmed])
  out$status_candidato[review] <- as.character(raw$apendice[review])
  out$id_registro[confirmed | review] <- as.character(raw$source_row_id[confirmed | review])
  out
}

.flora_endemic <- function(x, modo) {
  raw <- ppendemic::matching_ppendemic(x, max_dist = if (modo == "estricto") 0L else 2L)
  if (nrow(raw) != length(x) || !identical(as.integer(raw$sorter), seq_along(x))) {
    stop("ppendemic cambi\u00f3 el orden o n\u00famero de filas.", call. = FALSE)
  }
  out <- .flora_result(length(x))
  candidate <- .flora_clean(raw$Matched.Name)
  listed <- raw$Endemic.Tag %in% "Endemic" & raw$matched %in% TRUE
  exact <- .flora_same(x, candidate) & raw$direct_match %in% TRUE
  confirmed <- listed & exact
  review <- listed & !exact
  out$evaluacion[confirmed] <- "confirmado"
  out$evaluacion[review] <- "requiere_revision"
  out$presencia[confirmed] <- TRUE
  out$presencia[review] <- NA
  out$nombre_coincidente[confirmed] <- candidate[confirmed]
  out$nombre_aceptado[confirmed] <- candidate[confirmed]
  out$nombre_candidato[review] <- candidate[review]
  out$tipo_coincidencia[confirmed] <- "exact"
  out$tipo_coincidencia[review] <- "approximate"
  out$distancia <- suppressWarnings(as.double(raw$fuzzy_genus_dist))
  species_dist <- suppressWarnings(as.double(raw$fuzzy_species_dist))
  out$distancia[!is.na(species_dist)] <- species_dist[!is.na(species_dist)]
  out$distancia[confirmed] <- 0
  out$status_fuente[confirmed] <- "Endemic"
  out$status_candidato[review] <- "Endemic"
  out
}

.flora_redbook <- function(x, modo) {
  raw <- redbookperu::match_redbook_names(x, dist = if (modo == "estricto") 0 else 0.1,
                                         parser = "legacy",
                                         output = "detailed")
  if (nrow(raw) != length(x) || !identical(as.integer(raw$input_index), seq_along(x))) {
    stop("redbookperu cambi\u00f3 el orden o n\u00famero de filas.", call. = FALSE)
  }
  out <- .flora_result(length(x))
  invalid <- !(raw$input_valid %in% TRUE)
  confirmed <- raw$match_status %in% "exact" & raw$endemic_status %in% "endemic" & !invalid
  review <- raw$match_status %in% "fuzzy" & raw$endemic_status %in% "endemic" & !invalid
  ambiguous <- raw$match_status %in% "ambiguous" & !invalid
  out$evaluacion[invalid] <- "entrada_invalida"
  out$evaluacion[confirmed] <- "confirmado"
  out$evaluacion[review] <- "requiere_revision"
  out$evaluacion[ambiguous] <- "ambiguo"
  out$presencia[invalid | review | ambiguous] <- NA
  out$presencia[confirmed] <- TRUE
  out$nombre_coincidente[confirmed] <- .flora_clean(raw$redbook_name[confirmed])
  out$nombre_aceptado[confirmed] <- .flora_clean(raw$accepted_name[confirmed])
  out$nombre_candidato[review] <- .flora_clean(raw$accepted_name[review])
  missing_candidate <- review & is.na(out$nombre_candidato)
  out$nombre_candidato[missing_candidate] <- .flora_clean(raw$redbook_name[missing_candidate])
  out$tipo_coincidencia <- as.character(raw$match_status)
  out$distancia <- as.double(raw$match_distance)
  out$status_fuente[confirmed] <- "endemic"
  out$status_candidato[review] <- "endemic"
  out$id_registro[confirmed | review] <- as.character(raw$redbook_id[confirmed | review])
  out
}

.flora_ds43 <- function(x, modo) {
  raw <- peruflorads43::is_ds043_2006_ag(x, return_details = TRUE)
  if (nrow(raw) != length(x) || !identical(as.character(raw$Input.Name), x)) {
    stop("peruflorads43 cambi\u00f3 el orden o n\u00famero de filas.", call. = FALSE)
  }
  out <- .flora_result(length(x))
  found <- raw$Protected.DS043 %in% TRUE
  candidate <- .flora_clean(raw$Consolidated.Name)
  exact <- .flora_same(x, candidate) |
    .flora_same(x, raw$Original.Matched) |
    .flora_same(x, raw$Updated.Matched)
  confirmed <- found & exact
  review <- found & !exact
  out$evaluacion[confirmed] <- "confirmado"
  out$evaluacion[review] <- "requiere_revision"
  out$presencia[confirmed] <- TRUE
  out$presencia[review] <- NA
  out$nombre_coincidente[confirmed] <- candidate[confirmed]
  out$nombre_aceptado[confirmed] <- .flora_clean(raw$Accepted.Name[confirmed])
  out$nombre_candidato[review] <- candidate[review]
  out$tipo_coincidencia[confirmed] <- ifelse(raw$Is.Synonym[confirmed] %in% TRUE,
                                             "synonym", "exact")
  out$tipo_coincidencia[review] <- "approximate"
  out$distancia[confirmed] <- 0
  out$status_fuente[confirmed] <- as.character(raw$Consolidated.Category[confirmed])
  out$status_candidato[review] <- as.character(raw$Consolidated.Category[review])
  out
}
