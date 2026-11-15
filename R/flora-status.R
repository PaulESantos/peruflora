#' Resumir las consultas de flora peruana
#'
#' `flora_status()` conserva por separado las cuatro fuentes. Muestra también
#' los estados candidatos y marca sus filas con `requiere_revision = TRUE`.
#' Consulte [flora_match()] para distinguir los valores confirmados de los
#' candidatos antes de usarlos como evidencia.
#'
#' @param x Nombres o un resultado de [flora_match()].
#' @param ... Argumentos pasados a [flora_match()] cuando `x` contiene nombres.
#' @return Tibble con una fila por nombre de entrada.
#' @export
#' @examples
#' flora_status("Aa aurantiaca", fuentes = "cites")
flora_status <- function(x, ...) {
  detail <- if (inherits(x, "flora_match_result")) {
    if (length(list(...))) stop("No se usan argumentos adicionales con un resultado de `flora_match()`.", call. = FALSE)
    x
  } else flora_match(x, ...)
  .flora_validate_detail(detail)

  n <- if (nrow(detail)) max(detail$indice_entrada) else 0L
  if (!n) return(tibble::tibble(
    indice_entrada = integer(), nombre_original = character(),
    cites_apendice = character(), endemismo_actual = logical(),
    libro_rojo_endemico = logical(), ds043_categoria = character(),
    requiere_revision = logical()
  ))

  first <- !duplicated(detail$indice_entrada)
  original <- detail$nombre_original[first][order(detail$indice_entrada[first])]
  out <- tibble::tibble(
    indice_entrada = seq_len(n), nombre_original = original,
    cites_apendice = rep(NA_character_, n),
    endemismo_actual = rep(NA, n),
    libro_rojo_endemico = rep(NA, n),
    ds043_categoria = rep(NA_character_, n),
    requiere_revision = rep(FALSE, n)
  )

  for (source in unique(detail$fuente)) {
    block <- detail[detail$fuente == source, , drop = FALSE]
    idx <- block$indice_entrada
    status <- block$status_fuente
    candidates <- is.na(status) & !is.na(block$status_candidato)
    status[candidates] <- block$status_candidato[candidates]
    if (source == "cites") {
      out$cites_apendice[idx] <- status
    } else if (source == "endemismo_actual") {
      out$endemismo_actual[idx] <- ifelse(candidates, TRUE, block$presencia)
    } else if (source == "libro_rojo") {
      out$libro_rojo_endemico[idx] <- ifelse(candidates, TRUE, block$presencia)
    } else if (source == "ds043") {
      out$ds043_categoria[idx] <- status
    }
    out$requiere_revision[idx] <- out$requiere_revision[idx] |
      block$evaluacion %in% c("requiere_revision", "ambiguo")
  }
  out
}

.flora_validate_detail <- function(x) {
  required <- names(.flora_empty())
  if (!is.data.frame(x) || !all(required %in% names(x))) {
    stop("`x` no es un resultado v\u00e1lido de `flora_match()`.", call. = FALSE)
  }
  if (!nrow(x)) return(invisible(TRUE))
  idx <- x$indice_entrada
  if (!is.numeric(idx) || anyNA(idx) || any(idx < 1L) ||
      any(idx != floor(idx)) || !identical(sort(unique(idx)), seq_len(max(idx))) ||
      anyDuplicated(paste(idx, x$fuente, sep = "\r"))) {
    stop("El resultado de `flora_match()` tiene \u00edndices o fuentes duplicados.", call. = FALSE)
  }
  source <- unique(x$fuente)
  if (anyNA(source) || any(!source %in% names(.flora_source_packages())) ||
      any(vapply(source, function(s) !identical(sort(x$indice_entrada[x$fuente == s]),
                                              seq_len(max(idx))), logical(1)))) {
    stop("El resultado de `flora_match()` tiene cobertura incompleta.", call. = FALSE)
  }
  by_index <- split(x$nombre_original, idx)
  if (any(vapply(by_index, function(v) length(unique(v)) != 1L, logical(1)))) {
    stop("El resultado contiene nombres inconsistentes por \u00edndice.", call. = FALSE)
  }
  invisible(TRUE)
}
