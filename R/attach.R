.peruflora_packages <- function() {
  unname(.flora_source_packages())
}

.peruflora_version_display <- function(pkg) {
  version <- .flora_version(pkg)
  parts <- strsplit(version, ".", fixed = TRUE)[[1L]]
  dev <- suppressWarnings(as.numeric(parts)) >= 9000
  parts[!is.na(dev) & dev] <- cli::col_red(parts[!is.na(dev) & dev])
  paste(parts, collapse = ".")
}

.peruflora_attach_message <- function(attached) {
  if (!length(attached)) return(NULL)

  header <- cli::rule(
    left = cli::style_bold("Adjuntando paquetes principales de peruflora"),
    right = paste0("peruflora ", .peruflora_version_display("peruflora"))
  )
  attached <- sort(attached)
  versions <- vapply(attached, .peruflora_version_display, character(1))
  packages <- paste0(
    cli::col_green(cli::symbol$tick), " ",
    cli::col_blue(format(attached)), " ",
    cli::ansi_align(versions, max(cli::ansi_nchar(versions)))
  )
  if (length(packages) %% 2L) packages <- c(packages, "")
  left <- seq_len(length(packages) / 2L)
  rows <- paste0(packages[left], "     ", packages[-left])
  hint <- paste0(
    cli::col_cyan(cli::symbol$info), " Use ",
    cli::col_yellow("flora_match()"), " para consultar las cuatro fuentes."
  )
  paste(header, paste(rows, collapse = "\n"), hint, sep = "\n")
}

.peruflora_conflict_message <- function(conflicts) {
  if (!nrow(conflicts)) return(NULL)

  header <- cli::rule(
    left = cli::style_bold("Conflictos"),
    right = "peruflora_conflicts()"
  )
  lines <- vapply(seq_len(nrow(conflicts)), function(i) {
    pkgs <- strsplit(conflicts$paquetes[i], ", ", fixed = TRUE)[[1L]]
    winner <- paste0(cli::col_blue(pkgs[1L]), "::",
                     cli::col_green(paste0(conflicts$funcion[i], "()")))
    others <- paste0(cli::col_blue(pkgs[-1L]), "::",
                     conflicts$funcion[i], "()", collapse = ", ")
    paste0(cli::col_red(cli::symbol$cross), " ", winner,
           " enmascara ", others)
  }, character(1))
  hint <- paste0(
    cli::col_cyan(cli::symbol$info), " Use ",
    cli::col_yellow("paquete::funcion()"), " para evitar ambig\u00fcedades."
  )
  paste(header, paste(lines, collapse = "\n"), hint, sep = "\n")
}

#' Adjuntar los cuatro paquetes de flora
#' @return Invisiblemente, los nombres de paquetes adjuntados en esta llamada.
#' @export
peruflora_attach <- function() {
  pkgs <- .peruflora_packages()
  missing <- pkgs[!paste0("package:", pkgs) %in% search()]
  for (pkg in missing) {
    loc <- if (pkg %in% loadedNamespaces()) {
      dirname(getNamespaceInfo(pkg, "path"))
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE,
                                           lib.loc = loc,
                                           warn.conflicts = FALSE))
  }
  invisible(missing)
}

#' Versiones de los paquetes integrados
#' @return Tibble con paquetes, estado y versiones locales.
#' @export
peruflora_deps <- function() {
  pkgs <- .peruflora_packages()
  installed <- vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)
  versions <- vapply(seq_along(pkgs), function(i) {
    if (installed[i]) .flora_version(pkgs[i]) else NA_character_
  }, character(1))
  tibble::tibble(paquete = pkgs, instalado = unname(installed),
                 version = versions)
}

#' Informe del entorno de `peruflora`
#' @return Invisiblemente, la tabla de dependencias de [peruflora_deps()].
#' @export
peruflora_sitrep <- function() {
  deps <- peruflora_deps()
  version <- .flora_version("peruflora")
  cli::cli_h1("Entorno de peruflora")
  cli::cli_text("R: {as.character(getRversion())}")
  cli::cli_text("peruflora: {version}")
  for (i in seq_len(nrow(deps))) {
    cli::cli_text("{deps$paquete[i]}: {deps$version[i]}")
  }
  invisible(deps)
}

#' Conflictos entre funciones exportadas
#' @return Tibble con nombres de funciones y paquetes que las adjuntan.
#' @export
peruflora_conflicts <- function() {
  attached <- grep("^package:", search(), value = TRUE)
  core <- paste0("package:", .peruflora_packages())
  if (!length(intersect(attached, core))) {
    return(tibble::tibble(funcion = character(), paquetes = character()))
  }
  exported <- lapply(attached, function(env) {
    pkg <- sub("^package:", "", env)
    getNamespaceExports(pkg)
  })
  names(exported) <- attached
  all_names <- unlist(exported, use.names = FALSE)
  repeated <- unique(all_names[duplicated(all_names)])
  rows <- lapply(repeated, function(fn) {
    holders <- names(exported)[vapply(exported, function(v) fn %in% v, logical(1))]
    if (!any(holders %in% core)) return(NULL)
    funcs <- lapply(holders, function(pkg) get(fn, pos = pkg, inherits = FALSE))
    if (!all(vapply(funcs, is.function, logical(1))) ||
        length(unique(vapply(funcs, function(f) paste(deparse(body(f)), collapse = "\n"),
                             character(1)))) < 2L) return(NULL)
    tibble::tibble(funcion = fn,
                   paquetes = paste(sub("^package:", "", holders), collapse = ", "))
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) tibble::tibble(funcion = character(), paquetes = character())
  else tibble::as_tibble(do.call(rbind, rows))
}

.onAttach <- function(libname, pkgname) {
  attached <- peruflora_attach()
  if (isTRUE(getOption("peruflora.quiet"))) return(invisible())

  attach_message <- .peruflora_attach_message(attached)
  if (!is.null(attach_message)) packageStartupMessage(attach_message)

  if ("package:conflicted" %in% search()) return(invisible())
  conflict_message <- .peruflora_conflict_message(peruflora_conflicts())
  if (!is.null(conflict_message)) packageStartupMessage(conflict_message)
  invisible()
}
