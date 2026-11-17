app_records <- function(text = "", file = NULL, column = NULL) {
  lines <- if (is.null(text) || !length(text) || is.na(text[1]) || !nzchar(text[1])) character() else
    trimws(strsplit(text[1], "\r\n|\n|\r")[[1]])
  nonempty <- which(nzchar(lines))
  pasted <- data.frame(
    submitted_name = lines[nonempty],
    source_file = rep("Texto pegado", length(nonempty)),
    source_row = nonempty,
    stringsAsFactors = FALSE
  )
  if (is.null(file)) return(pasted)
  if (is.null(column) || !length(column) || !is.character(column) || !column %in% names(file$data)) {
    stop("Selecciona la columna que contiene los nombres cient\u00EDficos.", call. = FALSE)
  }
  uploaded <- data.frame(
    submitted_name = as.character(file$data[[column]]),
    source_file = rep(file$name, nrow(file$data)),
    source_row = seq_len(nrow(file$data)) + file$header_rows,
    stringsAsFactors = FALSE
  )
  uploaded <- uploaded[!is.na(uploaded$submitted_name) &
                         nzchar(trimws(uploaded$submitted_name)), , drop = FALSE]
  rbind(pasted, uploaded)
}

app_read_file <- function(path, filename, header = TRUE) {
  ext <- tolower(tools::file_ext(filename))
  if (!ext %in% c("txt", "csv", "tsv", "xlsx", "xls")) {
    stop("Usa un archivo TXT, CSV, TSV, XLS o XLSX.", call. = FALSE)
  }
  if (ext == "txt") {
    values <- readLines(path, warn = FALSE, encoding = "UTF-8")
    data <- data.frame(nombre_cientifico = values, stringsAsFactors = FALSE)
    header_rows <- 0L
  } else if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Instala 'readxl' para importar archivos de Excel.", call. = FALSE)
    }
    data <- as.data.frame(readxl::read_excel(path, col_names = header,
                                            .name_repair = "unique"),
                          stringsAsFactors = FALSE)
    header_rows <- as.integer(header)
  } else if (ext == "csv") {
    first_line <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
    sep <- if (length(first_line) && grepl(";", first_line[1]) && !grepl(",", first_line[1])) ";" else ","
    data <- utils::read.csv(path, header = header, sep = sep, check.names = FALSE,
                            stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM",
                            na.strings = c("NA"))
    header_rows <- as.integer(header)
  } else {
    data <- utils::read.delim(path, header = header, check.names = FALSE,
                              stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM",
                              na.strings = c("NA"))
    header_rows <- as.integer(header)
  }
  if (!ncol(data)) stop("El archivo no contiene columnas.", call. = FALSE)
  list(name = basename(filename), data = data, header_rows = header_rows)
}

app_guess_column <- function(data) {
  candidates <- c("scientific_name", "nombre_cientifico", "species_name",
                  "species", "taxon", "name", "submitted_name", "splist")
  normalized <- gsub("[[:space:]]+", "_", tolower(names(data)))
  hit <- match(candidates, normalized, nomatch = 0L)
  hit <- hit[hit > 0L]
  if (length(hit)) names(data)[hit[1]] else if (ncol(data) == 1L) names(data)[1] else ""
}

app_validate_records <- function(records) {
  if (!nrow(records)) stop("Ingresa al menos un nombre cient\u00EDfico.", call. = FALSE)
  if (nrow(records) > 10000L) stop("El m\u00E1ximo es de 10 000 nombres por consulta.", call. = FALSE)
  if (any(nchar(records$submitted_name) > 200L, na.rm = TRUE)) {
    stop("Cada nombre debe tener como m\u00E1ximo 200 caracteres.", call. = FALSE)
  }
  invisible(records)
}

app_query <- function(module, names, settings) {
  switch(module,
    integrada = {
      view <- if (is.character(settings$view) && length(settings$view) == 1L) settings$view else "resumen"
      modo <- if (is.character(settings$modo) && length(settings$modo) == 1L) settings$modo else "exploratorio"
      fuentes <- if (is.character(settings$fuentes) && length(settings$fuentes) > 0L) {
        settings$fuentes
      } else {
        c("cites", "endemismo_actual", "libro_rojo", "ds043")
      }
      if (identical(view, "resumen")) {
        flora_status(names, fuentes = fuentes, modo = modo)
      } else {
        flora_match(names, fuentes = fuentes, modo = modo)
      }
    },
    cites = {
      edition <- if (is.character(settings$edition) && length(settings$edition) == 1L && nzchar(settings$edition)) {
        settings$edition
      } else "2018"
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        as.integer(settings$distance)
      } else 2L
      synonyms <- if (is.logical(settings$synonyms) && length(settings$synonyms) == 1L) {
        settings$synonyms
      } else TRUE
      genus <- if (is.logical(settings$genus) && length(settings$genus) == 1L) {
        settings$genus
      } else FALSE
      citesperu::cites_match(
        names, taxon = "flora", edition = edition,
        max_dist = dist, allow_synonyms = synonyms,
        genus_fallback = genus, output = "standard"
      )
    },
    endemismo = {
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        as.integer(settings$distance)
      } else 2L
      ppendemic::matching_ppendemic(names, max_dist = dist)
    },
    libro_rojo = {
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        as.numeric(settings$distance)
      } else 0.1
      redbookperu::match_redbook_names(
        names, dist = dist, parser = "legacy", output = "detailed"
      )
    },
    ds043 = {
      peruflorads43::is_ds043_2006_ag(names, return_details = TRUE)
    },
    stop("M\u00F3dulo de consulta desconocido.", call. = FALSE)
  )
}

app_result_with_source <- function(result, records) {
  if (!is.data.frame(result)) {
    stop("La b\u00FAsqueda devolvi\u00F3 un objeto que no es una tabla.", call. = FALSE)
  }
  result <- as.data.frame(result, stringsAsFactors = FALSE)

  if ("requiere_revision" %in% names(result) && !"review_flag" %in% names(result)) {
    names(result)[names(result) == "requiere_revision"] <- "review_flag"
    result$review_flag <- result$review_flag %in% TRUE
  } else if ("requiere_revision" %in% names(result) && "review_flag" %in% names(result)) {
    result$requiere_revision <- NULL
  }

  if (!"review_flag" %in% names(result)) {
    if ("evaluacion" %in% names(result)) {
      review <- result$evaluacion %in% c("requiere_revision", "ambiguo")
    } else if ("match_assessment" %in% names(result)) {
      review <- result$match_assessment %in% c("requires_taxonomic_validation", "requires_species_validation", "ambiguous_match") |
        (!is.na(result$matched_dist) & result$matched_dist > 0)
    } else if ("match_status" %in% names(result)) {
      review <- result$match_status %in% c("fuzzy", "ambiguous") |
        (!is.na(result$match_distance) & result$match_distance > 0)
    } else if (all(c("Orig.Name", "Matched.Name", "matched") %in% names(result))) {
      fuzzy_sp <- if ("fuzzy_species_dist" %in% names(result)) suppressWarnings(as.numeric(result$fuzzy_species_dist)) else rep(NA_real_, nrow(result))
      fuzzy_gen <- if ("fuzzy_genus_dist" %in% names(result)) suppressWarnings(as.numeric(result$fuzzy_genus_dist)) else rep(NA_real_, nrow(result))
      has_dist <- (!is.na(fuzzy_sp) & fuzzy_sp > 0) | (!is.na(fuzzy_gen) & fuzzy_gen > 0)
      name_diff <- !is.na(result$Matched.Name) & tolower(trimws(result$Orig.Name)) != tolower(trimws(result$Matched.Name))
      is_direct <- if ("direct_match" %in% names(result)) result$direct_match %in% TRUE else FALSE
      review <- (!is.na(result$matched) & result$matched) & (!is_direct | has_dist | name_diff)
    } else if (all(c("Input.Name", "Consolidated.Name", "Protected.DS043") %in% names(result))) {
      name_diff <- tolower(trimws(result$Input.Name)) != tolower(trimws(result$Consolidated.Name))
      is_syn <- if ("Is.Synonym" %in% names(result)) result$Is.Synonym %in% TRUE else FALSE
      review <- (result$Protected.DS043 %in% TRUE) & (name_diff | is_syn)
    } else {
      review <- rep(FALSE, nrow(result))
    }
    result$review_flag <- review
  }

  if (!"review_observation" %in% names(result)) {
    result$review_observation <- ifelse(
      result$review_flag %in% TRUE,
      "Necesidad de revisi\u00F3n manual (coincidencia aproximada o ambigua)",
      NA_character_
    )
  }

  if ("indice_entrada" %in% names(result) && max(result$indice_entrada, 0L) <= nrow(records)) {
    result$source_file <- records$source_file[result$indice_entrada]
    result$source_row <- records$source_row[result$indice_entrada]
  } else if ("input_index" %in% names(result) && max(as.integer(result$input_index), 0L, na.rm = TRUE) <= nrow(records)) {
    idx <- as.integer(result$input_index)
    result$source_file <- records$source_file[idx]
    result$source_row <- records$source_row[idx]
  } else if ("sorter" %in% names(result) && max(as.integer(result$sorter), 0L, na.rm = TRUE) <= nrow(records)) {
    idx <- as.integer(result$sorter)
    result$source_file <- records$source_file[idx]
    result$source_row <- records$source_row[idx]
  } else if (nrow(result) == nrow(records)) {
    result$source_file <- records$source_file
    result$source_row <- records$source_row
  } else {
    stop("La b\u00FAsqueda devolvi\u00F3 un n\u00FAmero inesperado de filas.", call. = FALSE)
  }

  result
}

app_field_label <- function(fields) {
  labels <- c(
    indice_entrada = "\u00CDndice de entrada",
    nombre_original = "Nombre ingresado",
    submitted_name = "Nombre ingresado",
    name_submitted = "Nombre ingresado",
    input_name = "Nombre ingresado",
    `Input.Name` = "Nombre ingresado",
    `Orig.Name` = "Nombre ingresado",
    nombre_coincidente = "Nombre coincidente",
    nombre_aceptado = "Nombre aceptado",
    nombre_candidato = "Nombre candidato",
    matched_name = "Nombre encontrado",
    `Matched.Name` = "Nombre encontrado",
    accepted_name = "Nombre aceptado",
    `Accepted.Name` = "Nombre aceptado",
    `Consolidated.Name` = "Nombre consolidado",
    `Original.Matched` = "Nombre original coincidente",
    `Updated.Matched` = "Nombre actualizado coincidente",
    tipo_coincidencia = "Tipo de coincidencia",
    match_type = "Tipo de coincidencia",
    match_status = "Estado de coincidencia",
    evaluacion = "Evaluaci\u00F3n",
    match_assessment = "Evaluaci\u00F3n",
    distancia = "Distancia",
    matched_dist = "Distancia de coincidencia",
    match_distance = "Distancia de coincidencia",
    presencia = "Presencia confirmada",
    status_fuente = "Estado en fuente",
    status_candidato = "Estado candidato",
    cites_apendice = "Ap\u00E9ndice CITES",
    apendice = "Ap\u00E9ndice CITES",
    is_cites = "Listado en CITES",
    endemismo_actual = "Endemismo actual (WCVP)",
    `Endemic.Tag` = "Condici\u00F3n de endemismo",
    libro_rojo_endemico = "End\u00E9mico Libro Rojo (2006)",
    endemic_status = "Condici\u00F3n de endemismo",
    ds043_categoria = "Categor\u00EDa D.S. 043-2006-AG",
    `Consolidated.Category` = "Categor\u00EDa consolidada",
    `Protected.DS043` = "Protegido D.S. 043",
    `Is.Synonym` = "Es sin\u00F3nimo",
    requiere_revision = "Requiere revisi\u00F3n",
    review_flag = "Requiere revisi\u00F3n",
    review_observation = "Observaci\u00F3n",
    source_file = "Archivo de origen",
    source_row = "Fila de origen",
    id_registro = "ID de registro",
    referencia = "Referencia",
    fuente = "Fuente",
    edicion = "Edici\u00F3n",
    paquete_version = "Versi\u00F3n del paquete",
    edition_used = "Edici\u00F3n consultada",
    redbook_id = "ID Libro Rojo",
    redbook_name = "Nombre Libro Rojo",
    matched_via = "V\u00EDa de coincidencia",
    `Rank` = "Rango taxon\u00F3mico",
    familia = "Familia",
    accepted_family = "Familia aceptada",
    clase = "Clase"
  )
  unname(vapply(fields, function(field) {
    if (field %in% names(labels)) labels[[field]] else
      tools::toTitleCase(gsub("[_.]", " ", field))
  }, character(1)))
}
