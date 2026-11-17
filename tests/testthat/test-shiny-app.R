test_that("app records keep input order and file provenance", {
  file <- list(name = "nombres.csv", header_rows = 1L,
               data = data.frame(scientific_name = c("Swietenia macrophylla", "", NA,
                                                       "Aa aurantiaca")))
  result <- app_records("Sanchezia ovata\n\nPersea americana", file,
                        "scientific_name")
  expect_equal(result$submitted_name,
               c("Sanchezia ovata", "Persea americana", "Swietenia macrophylla",
                 "Aa aurantiaca"))
  expect_equal(result$source_row, c(1L, 3L, 2L, 5L))
  expect_error(app_records("", file, NULL), "Selecciona la columna")
})

test_that("file input supports headers and headerless tables", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("scientific_name,id", "Swietenia macrophylla,1"), path)
  with_header <- app_read_file(path, "nombres.csv")
  expect_identical(app_guess_column(with_header$data), "scientific_name")
  expect_equal(app_records("", with_header, "scientific_name")$source_row, 2L)
  without_header <- app_read_file(path, "nombres.csv", header = FALSE)
  expect_equal(nrow(without_header$data), 2L)
  expect_equal(without_header$header_rows, 0L)
})

test_that("Excel imports preserve worksheet row numbers", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(path), add = TRUE)
  writexl::write_xlsx(data.frame(scientific_name = c("Swietenia macrophylla",
                                                     "Aa aurantiaca")), path)
  file <- app_read_file(path, "nombres.xlsx")
  expect_equal(app_records("", file, "scientific_name")$source_row, 2:3)
})

test_that("app limits oversized batches before launching a job", {
  records <- app_records("Swietenia macrophylla")
  expect_invisible(app_validate_records(records))
  expect_error(app_validate_records(records[FALSE, ]), "al menos un nombre")
  expect_error(app_validate_records(records[rep(1, 10001), ]), "10 000")
})

test_that("five query views return row-aligned results", {
  species <- c("Swietenia macrophylla", "Aa aurantiaca")
  settings <- list(
    integrada = list(view = "resumen", modo = "exploratorio"),
    cites = list(edition = "2018", distance = 1, synonyms = TRUE, genus = FALSE),
    endemismo = list(distance = 2),
    libro_rojo = list(distance = 0.1),
    ds043 = list()
  )
  records <- app_records(paste(species, collapse = "\n"))
  for (module in names(settings)) {
    result <- app_query(module, species, settings[[module]])
    expect_true(nrow(result) >= length(species), info = module)
    with_source <- app_result_with_source(result, records)
    if (nrow(result) == length(species)) {
      expect_equal(with_source$source_row, 1:2, info = module)
    } else {
      expect_equal(unique(with_source$source_row), 1:2, info = module)
    }
  }
})

test_that("app exports mark approximate matches for review", {
  for (module in c("integrada", "cites", "endemismo", "libro_rojo", "ds043")) {
    name <- switch(module,
      endemismo = "Aa aurantiacaa",
      libro_rojo = "Verbesina andinaa",
      "Catleya maxima"
    )
    records <- app_records(name)
    value <- app_query(module, records$submitted_name, list())
    exported <- app_result_with_source(value, records)
    expect_true(exported$review_flag[1], info = module)
    expect_true(grepl("revisi\u00F3n", exported$review_observation[1], ignore.case = TRUE), info = module)
  }
})

test_that("app_result_with_source does not duplicate review column", {
  records <- app_records("Swietenia macrophylla")
  res <- app_query("integrada", records$submitted_name, list(view = "resumen"))
  exported <- app_result_with_source(res, records)
  expect_false("requiere_revision" %in% names(exported))
  expect_true("review_flag" %in% names(exported))
  expect_equal(sum(names(exported) == "review_flag"), 1L)
  headers <- app_field_label(names(exported))
  expect_equal(sum(headers == "Requiere revisi\u00F3n"), 1L)
})

test_that("three spelling variations of Cattleya maxima return consistent results", {
  names <- c("Cattleya maxima", "Catleya maxima", "Catleya maximma")
  st <- flora_status(names)
  expect_identical(st$cites_apendice, c("II", "II", "II"))
  expect_identical(st$ds043_categoria, c("CR", "CR", "CR"))
  expect_identical(st$endemismo_actual, c(FALSE, FALSE, FALSE))
  expect_identical(st$libro_rojo_endemico, c(FALSE, FALSE, FALSE))
  expect_identical(st$requiere_revision, c(FALSE, TRUE, TRUE))
})

test_that("the interface renders all five modules", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  html <- htmltools::renderTags(peruflora_app_ui())$html
  for (id in c("integrada", "cites", "endemismo", "libro_rojo", "ds043")) {
    expect_true(grepl(paste0('data-value="', id, '"'), html, fixed = TRUE), info = id)
  }
  for (label in c("Consultar todas las fuentes", "Consultar CITES Flora",
                  "Consultar endemismo actual", "Consultar Libro Rojo",
                  "Consultar D.S. 043-2006-AG")) {
    expect_true(grepl(label, html, fixed = TRUE), info = label)
  }
  expect_true(grepl('id="names_text"', html, fixed = TRUE))
  expect_false(grepl('value="Swietenia macrophylla', html, fixed = TRUE))
})

test_that("each module runs its own query", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  old_async <- getOption("peruflora.async")
  options(peruflora.async = FALSE)
  on.exit(options(peruflora.async = old_async), add = TRUE)
  called <- character()
  local_mocked_bindings(
    app_query = function(module, names, settings) {
      called <<- c(called, module)
      data.frame(submitted_name = names, queried_module = module, stringsAsFactors = FALSE)
    }
  )
  for (selected_module in c("integrada", "cites", "endemismo", "libro_rojo", "ds043")) {
    shiny::testServer(app_module_server,
      args = list(id = selected_module, module = selected_module,
                  records = shiny::reactive(app_records("Swietenia macrophylla"))), {
        session$setInputs(run = 1L)
      })
  }
  expect_identical(called, c("integrada", "cites", "endemismo", "libro_rojo", "ds043"))
})

test_that("app supports semicolon-delimited CSV files from Spanish Excel", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("scientific_name;id", "Swietenia macrophylla;1", "Aa aurantiaca;2"), path)
  parsed <- app_read_file(path, "nombres_excel.csv")
  expect_identical(app_guess_column(parsed$data), "scientific_name")
  expect_equal(nrow(parsed$data), 2L)
  expect_equal(ncol(parsed$data), 2L)
  expect_equal(parsed$data$scientific_name, c("Swietenia macrophylla", "Aa aurantiaca"))
})

test_that("peruflora_app and flora_app aliases and shiny.appobj work", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  expect_identical(flora_app, run_peruflora_app)
  app <- peruflora_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("app_dt_language returns Spanish localization strings", {
  lang <- app_dt_language()
  expect_type(lang, "list")
  expect_equal(lang$search, "Buscar:")
  expect_true(grepl("registros", lang$lengthMenu))
})

test_that("app_module_summary_cards produces KPI metrics for query results", {
  skip_if_not_installed("shiny")
  df <- data.frame(
    indice_entrada = 1:2,
    nombre_original = c("Swietenia macrophylla", "Aa aurantiaca"),
    cites_apendice = c("II", "II"),
    endemismo_actual = c(FALSE, TRUE),
    libro_rojo_endemico = c(FALSE, TRUE),
    ds043_categoria = c("VU", NA),
    requiere_revision = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )
  cards_ui <- app_module_summary_cards(df, "integrada")
  expect_s3_class(cards_ui, "shiny.tag")
  html <- htmltools::renderTags(cards_ui)$html
  expect_true(grepl("pf-card-total", html))
  expect_true(grepl("pf-card-cites", html))
  expect_true(grepl("pf-card-endemic", html))
})
