test_that("four sources preserve positions, duplicates and invalid entries", {
  names <- c("Swietenia macrophylla", "Aa aurantiaca",
             "Swietenia macrophylla", NA_character_, "")
  result <- flora_match(names)
  expect_s3_class(result, "flora_match_result")
  expect_equal(nrow(result), 4L * length(names))
  for (source in unique(result$fuente)) {
    part <- result[result$fuente == source, ]
    expect_identical(part$indice_entrada, seq_along(names))
    expect_identical(part$nombre_original, names)
    expect_identical(part$evaluacion[4:5], rep("entrada_invalida", 2))
    expect_true(all(is.na(part$presencia[4:5])))
    expect_identical(as.list(part[1, -1]), as.list(part[3, -1]))
  }
  expect_identical(result$fuente, rep(c("cites", "endemismo_actual",
                                      "libro_rojo", "ds043"), each = length(names)))
})

test_that("confirmed statuses retain their source and do not imply other statuses", {
  result <- flora_match(c("Swietenia macrophylla", "Aa aurantiaca",
                          "Sanchezia ovata", "Cattleya maxima", "Persea americana"))
  summary <- flora_status(result)
  expect_equal(summary$cites_apendice[1], "II")
  expect_true(summary$endemismo_actual[2])
  expect_true(summary$libro_rojo_endemico[3])
  expect_equal(summary$ds043_categoria[4], "CR")
  expect_false(summary$endemismo_actual[1])
  expect_true(is.na(summary$ds043_categoria[5]))
  expect_false(any(summary$requiere_revision))
})

test_that("approximate names are candidates only", {
  strict <- flora_match("Catleya maxima")
  ds <- strict[strict$fuente == "ds043", ]
  expect_equal(ds$evaluacion, "requiere_revision")
  expect_true(is.na(ds$presencia))
  expect_equal(ds$status_candidato, "CR")
  expect_true(is.na(ds$status_fuente))

  exploratory <- flora_match(c("Aa aurantiaaia", "Catleya maxima",
                               "Sanchezia ovataa"), modo = "exploratorio")
  expect_true(any(exploratory$evaluacion == "requiere_revision"))
  candidates <- exploratory$evaluacion == "requiere_revision"
  expect_true(all(is.na(exploratory$presencia[candidates])))
  expect_true(all(is.na(exploratory$status_fuente[candidates])))
  expect_true(all(flora_status(exploratory)$requiere_revision))
})

test_that("default inventory summary shows candidate categories with review flag", {
  inventory <- tibble::tibble(
    indice_entrada = 1:5,
    parcela = c("P01", "P01", "P02", "P02", "P03"),
    nombre_cientifico = c("Aa aurantiaca", "Cattleya maxima",
                          "Persea americana", "Aa aurantiaca", "Catleya maxima"),
    abundancia = c(2, 1, 4, 3, 1)
  )
  status <- flora_status(inventory, name_col = "nombre_cientifico")
  expect_identical(status$cites_apendice, c("II", "II", NA_character_, "II", "II"))
  expect_identical(status$ds043_categoria, c(NA_character_, "CR", NA_character_,
                                           NA_character_, "CR"))
  expect_identical(status$requiere_revision, c(FALSE, FALSE, FALSE, FALSE, TRUE))

  detail <- flora_match(inventory, name_col = "nombre_cientifico")
  typo <- detail[detail$indice_entrada == 5, ]
  suggested <- typo$fuente %in% c("cites", "ds043")
  expect_true(all(typo$evaluacion[suggested] == "requiere_revision"))
  expect_true(all(is.na(typo$status_fuente[suggested])))
  expect_identical(typo$status_candidato[suggested], c("II", "CR"))
})

test_that("indeterminate names do not become negative species results", {
  result <- flora_match(c("Piper sp.", "Piper spp.", "Piper"))
  expect_true(all(result$evaluacion == "requiere_revision"))
  expect_true(all(is.na(result$presencia)))
  expect_true(all(flora_status(result)$requiere_revision))
})

test_that("input validation and selected sources work", {
  expect_error(flora_match(1), "`x`")
  expect_error(flora_match(data.frame(id = 1, label = "Aa aurantiaca")), "name_col")
  expect_error(flora_match("Aa aurantiaca", name_col = "species"), "name_col")
  expect_error(flora_match("Aa aurantiaca", fuentes = "fauna"), "fuentes")
  expect_error(flora_match("Aa aurantiaca", fuentes = c("cites", "cites")), "fuentes")
  expect_error(flora_match("Aa aurantiaca", fuentes = character()), "fuentes")
  expect_error(flora_match("Aa aurantiaca", modo = "desconocido"), "arg")

  result <- flora_match(data.frame(id = 1:2, Nombre_Cientifico =
                                     c("Aa aurantiaca", "Persea americana")),
                        fuentes = "endemismo_actual")
  expect_equal(nrow(result), 2L)
  expect_true(flora_status(result)$endemismo_actual[1])
  expect_true(all(is.na(flora_status(result)$cites_apendice)))
})

test_that("empty results retain a typed schema", {
  result <- flora_match(character())
  expect_s3_class(result, "flora_match_result")
  expect_equal(nrow(result), 0L)
  expect_equal(nrow(flora_status(result)), 0L)
  expect_equal(nrow(flora_status(character())), 0L)
})

test_that("metapackage reports its four independent dependencies", {
  deps <- peruflora_deps()
  expect_identical(deps$paquete,
                   c("citesperu", "ppendemic", "redbookperu", "peruflorads43"))
  expect_true(all(deps$instalado))
  expect_equal(nrow(flora_fuentes()), 4L)
  expect_s3_class(peruflora_conflicts(), "tbl_df")
  expect_identical(peruflora_attach(), character())
})

test_that("startup banner lists newly attached packages and versions", {
  expect_null(peruflora:::.peruflora_attach_message(character()))
  banner <- peruflora:::.peruflora_attach_message(c("ppendemic", "citesperu"))
  plain <- cli::ansi_strip(banner)
  expect_match(plain, "Adjuntando paquetes principales de peruflora")
  expect_match(plain, "peruflora [0-9]+\\.")
  expect_match(plain, "citesperu")
  expect_match(plain, "ppendemic")
  expect_match(plain, "flora_match\\(\\)")
  expect_null(peruflora:::.peruflora_conflict_message(peruflora_conflicts()[0, ]))
})
