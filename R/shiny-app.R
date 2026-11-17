#' Abrir la aplicación interactiva de peruflora
#'
#' Consulta nombres científicos de plantas en cinco vistas: integrada,
#' CITES Flora, endemismo actual (WCVP), Libro Rojo de plantas endémicas y
#' categorías de amenaza del D.S. 043-2006-AG. La entrada puede pegarse o
#' importarse desde TXT, CSV, TSV, XLS o XLSX. Las búsquedas se ejecutan en un
#' proceso en segundo plano (con respaldo automático para ejecución síncrona) y los resultados
#' se pueden descargar en CSV o XLSX.
#'
#' @param host Interfaz de red para Shiny. Por defecto, solo el equipo local (`"127.0.0.1"`).
#' @param port Puerto. `NULL` permite que Shiny elija uno libre.
#' @param launch.browser Abrir el navegador al iniciar la aplicación.
#' @param max_request_size Tamaño máximo de carga de archivos en bytes. Por defecto, 20 MB.
#' @param options Lista de opciones pasadas a \code{\link[shiny:shinyApp]{shiny::shinyApp}}.
#' @return Devuelve de forma invisible el resultado de `shiny::runApp()`. En `peruflora_app()`,
#'   devuelve el objeto `shinyApp`.
#' @encoding UTF-8
#' @export
run_peruflora_app <- function(host = "127.0.0.1", port = NULL,
                             launch.browser = interactive(),
                             max_request_size = 20 * 1024^2,
                             options = list()) {
  check_peruflora_app_deps()
  if (!isTRUE(l10n_info()[["UTF-8"]])) {
    previous_locale <- Sys.getlocale("LC_CTYPE")
    suppressWarnings(Sys.setlocale("LC_CTYPE", ""))
    on.exit(suppressWarnings(Sys.setlocale("LC_CTYPE", previous_locale)), add = TRUE)
  }
  previous_max_size <- getOption("shiny.maxRequestSize")
  current_max <- if (is.null(previous_max_size)) 0 else previous_max_size
  options(shiny.maxRequestSize = max(max_request_size, current_max))
  on.exit(options(shiny.maxRequestSize = previous_max_size), add = TRUE)
  app <- peruflora_app(options = options)
  shiny::runApp(
    app,
    host = host, port = port, launch.browser = launch.browser
  )
}

#' @rdname run_peruflora_app
#' @export
flora_app <- run_peruflora_app

#' @rdname run_peruflora_app
#' @export
peruflora_app <- function(options = list()) {
  check_peruflora_app_deps()
  shiny::shinyApp(
    ui = peruflora_app_ui(),
    server = peruflora_app_server,
    options = options
  )
}

check_peruflora_app_deps <- function() {
  needed <- c("shiny", "DT")
  missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Instala las dependencias de la app: ", paste(missing, collapse = ", "),
         ".", call. = FALSE)
  }
}

app_dt_language <- function() {
  list(
    search = "Buscar:",
    lengthMenu = "Mostrar _MENU_ registros",
    info = "Mostrando _START_ a _END_ de _TOTAL_ registros",
    infoEmpty = "Mostrando 0 a 0 de 0 registros",
    infoFiltered = "(filtrado de _MAX_ registros en total)",
    zeroRecords = "No se encontraron registros coincidentes",
    emptyTable = "No hay datos disponibles en la tabla",
    paginate = list(
      first = "Primero",
      previous = "Anterior",
      `next` = "Siguiente",
      last = "\u00DAltimo"
    )
  )
}

app_module_controls <- function(id, module) {
  ns <- shiny::NS(id)
  advanced <- function(...) shiny::tags$details(
    class = "pf-advanced", shiny::tags$summary("Opciones avanzadas"), ...
  )
  switch(module,
    integrada = shiny::tagList(
      shiny::radioButtons(ns("view"), "Resultado", inline = TRUE,
                          choices = c("Resumen" = "resumen", "Detalle" = "detalle"),
                          selected = "resumen"),
      advanced(
        shiny::selectInput(ns("modo"), "Modo de concordancia",
                           choices = c("Exploratorio (candidatos para revisi\u00F3n)" = "exploratorio",
                                       "Estricto (solo distancias m\u00EDnimas)" = "estricto"),
                           selected = "exploratorio"),
        shiny::tags$p(class = "pf-hint",
                      "Las coincidencias aproximadas se conservan como candidatas para revisi\u00F3n manual; no se confirman autom\u00E1ticamente.")
      )
    ),
    cites = shiny::tagList(
      shiny::selectInput(ns("edition"), "Edici\u00F3n CITES Flora",
                         c("MINAM 2018 (oficial)" = "2018", "M\u00E1s reciente" = "latest", "Todas" = "all")),
      advanced(
        shiny::numericInput(ns("distance"), "Ediciones permitidas", 2, min = 0, step = 1),
        shiny::checkboxInput(ns("synonyms"), "Aceptar sin\u00F3nimos", TRUE),
        shiny::checkboxInput(ns("genus"), "Permitir coincidencia por g\u00E9nero", FALSE),
        shiny::tags$p(class = "pf-hint",
                      "Los candidatos aproximados requieren validaci\u00F3n taxon\u00F3mica y no se cuentan como listados confirmados.")
      )
    ),
    endemismo = shiny::tagList(
      shiny::tags$div(class = "pf-hint-box",
        shiny::tags$span("\U0001F33F Cat\u00E1logo de especies end\u00E9micas del Per\u00FA basado en World Checklist of Vascular Plants (WCVP V-16).")
      ),
      advanced(
        shiny::numericInput(ns("distance"), "Ediciones m\u00E1ximas (fuzzy)", 2, min = 0, max = 3, step = 1),
        shiny::tags$p(class = "pf-hint", "0 = solo coincidencias directas. Las correcciones aproximadas requieren revisi\u00F3n manual.")
      )
    ),
    libro_rojo = shiny::tagList(
      shiny::tags$div(class = "pf-hint-box",
        shiny::tags$span("\U0001F4D6 Libro Rojo de las Plantas End\u00E9micas del Per\u00FA (Le\u00F3n et al., 2006) con taxonom\u00EDa actualizada.")
      ),
      advanced(
        shiny::numericInput(ns("distance"), "Distancia m\u00E1xima (fracci\u00F3n)", 0.1,
                            min = 0, max = 0.25, step = 0.05),
        shiny::tags$p(class = "pf-hint", "0 = coincidencia exacta; 0.1 = permite variaciones ortogr\u00E1ficas menores.")
      )
    ),
    ds043 = shiny::tagList(
      shiny::tags$div(class = "pf-hint-box",
        shiny::tags$span("\u2696\uFE0F Lista oficial de flora silvestre legalmente amenazada en el Per\u00FA bajo el D.S. 043-2006-AG.")
      )
    )
  )
}

app_module_ui <- function(id, module, title, description) {
  ns <- shiny::NS(id)
  action_label <- switch(module,
    integrada = "Consultar todas las fuentes",
    cites = "Consultar CITES Flora",
    endemismo = "Consultar endemismo actual",
    libro_rojo = "Consultar Libro Rojo",
    ds043 = "Consultar D.S. 043-2006-AG"
  )
  shiny::div(class = "pf-module-card",
    shiny::div(class = "pf-toolbar",
      shiny::div(class = "pf-toolbar-left",
        shiny::div(class = "pf-toolbar-desc",
          shiny::tags$strong(class = "pf-desc-badge", title),
          shiny::tags$span(class = "pf-desc-text", paste("\u2014", description))
        ),
        shiny::div(class = "pf-toolbar-inputs",
          app_module_controls(id, module)
        )
      ),
      shiny::div(class = "pf-toolbar-actions",
        shiny::actionButton(ns("run"), action_label,
                            class = "btn pf-btn-run"),
        shiny::uiOutput(ns("cancel_ui")),
        shiny::tags$div(class = "pf-status", role = "status", `aria-live` = "polite",
          shiny::textOutput(ns("status"), inline = TRUE))
      )
    ),
    if (identical(module, "integrada")) shiny::div(class = "pf-alert-info",
      shiny::tags$span(class = "pf-alert-icon", "\u2139\uFE0F"),
      shiny::tags$div(
        shiny::tags$strong("Nota de interpretaci\u00F3n normativa y taxon\u00F3mica: "),
        "peruflora integra cuatro fuentes independientes de flora peruana. Las coincidencias aproximadas o por sin\u00F3nimo permanecen como candidatas y se se\u00F1alan para revisi\u00F3n manual. El Libro Rojo (2006) aporta valor t\u00E9cnico-hist\u00F3rico, mientras que el D.S. 043-2006-AG y CITES establecen reg\u00EDmenes legales espec\u00EDficos."
      )
    ),
    if (identical(module, "cites")) shiny::div(class = "pf-alert-info",
      shiny::tags$span(class = "pf-alert-icon", "\U0001F310"),
      shiny::tags$div(
        shiny::tags$strong("Alcance normativo CITES: "),
        "Regula el comercio internacional de especies de flora listadas en los Ap\u00E9ndices I, II y III (edici\u00F3n MINAM 2018). El listado CITES por s\u00ED solo no acredita residencia exclusiva ni endemismo en territorio peruano."
      )
    ),
    if (identical(module, "endemismo")) shiny::div(class = "pf-alert-info",
      shiny::tags$span(class = "pf-alert-icon", "\U0001F33F"),
      shiny::tags$div(
        shiny::tags$strong("Cat\u00E1logo de endemismo actual (ppendemic): "),
        "Eval\u00FAa la condici\u00F3n de tax\u00F3n end\u00E9mico para el Per\u00FA utilizando el cat\u00E1logo mundial World Checklist of Vascular Plants (WCVP V-16, 2026). Las coincidencias aproximadas deben validarse taxon\u00F3micamente."
      )
    ),
    if (identical(module, "libro_rojo")) shiny::div(class = "pf-alert-info",
      shiny::tags$span(class = "pf-alert-icon", "\U0001F4D6"),
      shiny::tags$div(
        shiny::tags$strong("Libro Rojo de Plantas End\u00E9micas (2006): "),
        "Recopila la evaluaci\u00F3n t\u00E9cnica hist\u00F3rica de Le\u00F3n et al. (2006) con categor\u00EDas UICN aplicadas a especies end\u00E9micas. No sustituye la categorizaci\u00F3n legal vinculante del D.S. 043-2006-AG."
      )
    ),
    if (identical(module, "ds043")) shiny::div(class = "pf-alert-info",
      shiny::tags$span(class = "pf-alert-icon", "\u2696\uFE0F"),
      shiny::tags$div(
        shiny::tags$strong("Marco legal nacional (D.S. 043-2006-AG): "),
        "Aprueba la categorizaci\u00F3n oficial de especies amenazadas de flora silvestre en el Per\u00FA (Peligro Cr\u00EDtico CR, En Peligro EN, Vulnerable VU, Casi Amenazado NT)."
      )
    ),
    shiny::div(id = ns("results"), class = "pf-results",
      shiny::uiOutput(ns("summary")),
      shiny::uiOutput(ns("table_help")),
      DT::DTOutput(ns("table")),
      shiny::uiOutput(ns("downloads")),
      shiny::uiOutput(ns("detail"))
    )
  )
}

peruflora_app_ui <- function() {
  shiny::fluidPage(
    title = "peruflora | Reconciliaci\u00F3n Taxon\u00F3mica de Flora del Per\u00FA",
    shiny::tags$head(
      shiny::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      shiny::tags$script(shiny::HTML("Shiny.addCustomMessageHandler('pf-reset-file', function() { var el = document.getElementById('file'); if (el) { el.value = ''; el.dispatchEvent(new Event('change', {bubbles:true})); } }); Shiny.addCustomMessageHandler('pf-scroll-results', function(id) { var el = document.getElementById(id); if (el) el.scrollIntoView({behavior:'smooth', block:'start'}); });")),
      shiny::tags$style(shiny::HTML("\
      @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;0,800;1,400;1,600&family=JetBrains+Mono:wght@400;500;600;700&display=swap');

      :root {
        --pf-font-sans: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        --pf-font-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      }
      body {background:#f4f7f5;color:#102e22;font-family:var(--pf-font-sans);font-size:14.5px;line-height:1.5;-webkit-font-smoothing:antialiased;-moz-osx-font-smoothing:grayscale}
      .container-fluid {max-width:1320px;margin:auto;padding:18px 24px 48px}

      /* Sleek Top Navbar */
      .pf-navbar {background:linear-gradient(135deg,#0b2e23 0%,#14533d 100%);color:white;padding:16px 22px;border-radius:16px;margin-bottom:16px;display:flex;align-items:center;justify-content:space-between;gap:20px;box-shadow:0 8px 24px rgba(11,46,35,.12)}
      .pf-nav-brand {display:flex;align-items:center;gap:14px;min-width:0}
      .pf-nav-logo {display:inline-flex;align-items:center;justify-content:center;width:38px;height:38px;background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.24);border-radius:10px;color:#8eedb9;box-shadow:inset 0 1px 1px rgba(255,255,255,.15);flex-shrink:0}
      .pf-nav-svg {display:block;width:22px;height:22px}
      .pf-brand-title {font-family:var(--pf-font-sans);font-size:1.45rem;font-weight:800;letter-spacing:-.03em;margin:0;line-height:1;display:inline-block;vertical-align:middle;color:#ffffff}
      .pf-brand-tag {font-family:var(--pf-font-sans);font-size:.72rem;font-weight:750;background:rgba(16,185,129,.25);color:#8eedb9;border:1px solid rgba(142,237,185,.32);border-radius:6px;padding:2px 7px;margin-left:6px;vertical-align:middle;letter-spacing:.02em}
      .pf-brand-sub {font-family:var(--pf-font-sans);font-size:.82rem;color:#c7e4d3;display:block;margin-top:5px;font-weight:500;letter-spacing:-.01em}
      .pf-nav-badges {display:flex;align-items:center;justify-content:flex-end;gap:5px;flex-wrap:wrap;max-width:440px}
      .pf-nav-badge {font-family:var(--pf-font-sans);font-size:.7rem;font-weight:650;color:#d8efe1;background:rgba(255,255,255,.07);border:1px solid rgba(255,255,255,.17);border-radius:99px;padding:3px 9px;white-space:nowrap;letter-spacing:.01em}

      /* Unified Cards */
      .pf-card,.pf-module-card {background:white;border:1px solid #d8e5dd;border-radius:14px;box-shadow:0 5px 18px rgba(11,46,35,.04);padding:20px 22px;margin-bottom:16px}
      .pf-section-heading {display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:10px}
      .pf-heading-left {display:flex;align-items:center;gap:10px}
      .pf-step {display:inline-grid;place-items:center;width:26px;height:26px;border-radius:50%;background:#e2f4ea;color:#0b3926;border:1.5px solid #bce2cd;font-weight:800;font-size:.84rem;flex:none}
      .pf-section-heading h2 {font-family:var(--pf-font-sans);font-size:1.14rem;font-weight:750;letter-spacing:-.02em;color:#0d2d20;margin:0}

      /* Step 1 Inputs & Actions */
      .pf-input-actions {display:flex;align-items:center;gap:8px}
      .pf-btn-sm {font-size:.82rem !important;padding:5px 12px !important;font-weight:680 !important}
      .pf-btn-subtle {background:#edf5f0;color:#144a33;border:1px solid #c9dfd2;border-radius:7px;transition:all .15s ease}
      .pf-btn-subtle:hover {background:#ddece2;color:#0c3322;border-color:#b0d3be}
      .pf-btn-clear {color:#962d22;background:#fdf5f4;border-color:#f0d5d2}
      .pf-btn-clear:hover {background:#fae5e3;color:#782218;border-color:#e2beba}
      .pf-inputs {display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:22px}
      .pf-input-col-title {font-family:var(--pf-font-sans);font-weight:700;font-size:.86rem;color:#123e2d;margin-bottom:6px;display:block;letter-spacing:-.01em}
      .pf-inputs textarea {border-radius:9px;border:1.5px solid #cbdbd1;font-family:var(--pf-font-mono);font-size:.88rem;line-height:1.55;font-weight:500;padding:10px 12px;min-height:100px;max-height:240px;resize:vertical;color:#0e291e;background:#fafcfb}
      .pf-inputs textarea:focus,.pf-inputs .form-control:focus {border-color:#1c694a;box-shadow:0 0 0 3px rgba(28,105,74,.15);background:#ffffff}
      .pf-input-footer-row {margin-top:6px;display:flex;align-items:center;justify-content:space-between}
      .pf-count-badge {display:inline-flex;align-items:center;gap:7px;background:#eaf5ef;border:1px solid #bfe0ce;border-radius:99px;padding:3.5px 12px;color:#0e3e2c;font-weight:700;font-size:.82rem}
      .pf-count-dot {width:7px;height:7px;border-radius:50%;background:#10b981;box-shadow:0 0 0 2px rgba(16,185,129,.25)}
      .pf-hint {color:#506e5e;font-size:.79rem;margin:0}
      .pf-hint-inline {color:#506e5e;font-size:.79rem}

      /* Step 1 Upload Column */
      .pf-upload {border-left:1px solid #e1ebe4;padding-left:22px;min-width:0;display:flex;flex-direction:column}
      .pf-upload .shiny-input-container {margin-bottom:4px;width:100%}
      .pf-upload .input-group {width:100%}
      .pf-upload .btn-file {background:#edf4f0;color:#103927;border:1.5px solid #bcd5c7;font-weight:700;font-size:.84rem;border-radius:8px 0 0 8px;padding:6.5px 13px}
      .pf-upload .btn-file:hover {background:#dcebe1;border-color:#a8c9b6}
      .pf-upload .input-group .form-control {min-width:0;overflow:hidden;text-overflow:ellipsis;border:1.5px solid #cbdcd2;border-left:0;border-radius:0 8px 8px 0;background:#ffffff;box-shadow:none;font-size:.84rem;height:auto;padding:6.5px 11px;color:#1a372b}
      .pf-formats-bar {font-size:.79rem;color:#4f6e5e;margin:auto 0 0;padding-top:12px;display:flex;align-items:center;gap:5px;flex-wrap:wrap}
      .pf-format-pill {font-family:var(--pf-font-mono);background:#e6f3ec;color:#114d34;border:1px solid #c9ded2;padding:1.5px 7px;border-radius:4px;font-size:.72rem;font-weight:700}
      .pf-file-settings {background:#f6faf7;border:1px solid #dee8e1;border-radius:8px;padding:10px;margin-top:8px}
      .pf-file-settings .form-group {margin-bottom:0}.pf-file-settings .checkbox {margin-top:0}
      .pf-file-preview {margin-top:8px}
      .pf-file-preview summary {cursor:pointer;color:#1c533c;font-weight:650;font-size:.83rem}

      /* Step 2 Workflow & Nav Pills */
      .pf-workflow {margin-top:18px}
      .pf-workflow>.pf-section-heading {margin-bottom:8px}
      .pf-workflow .nav-pills {display:flex;flex-wrap:wrap;gap:7px;margin-bottom:12px;border-bottom:0}
      .pf-workflow .nav-pills>li {float:none;margin:0}
      .pf-workflow .nav-pills>li>a {font-family:var(--pf-font-sans);border-radius:8px;color:#174734;font-weight:700;font-size:.88rem;letter-spacing:-.01em;padding:7.5px 15px;background:#edf4f0;border:1.5px solid #d0e2d7;display:inline-flex;align-items:center;gap:6px;transition:all .15s ease}
      .pf-workflow .nav-pills>li:not(.active)>a:hover {background:#dfeee4;color:#0c3222;border-color:#b3d4c1}
      .pf-workflow .nav-pills>li.active>a,.pf-workflow .nav-pills>li.active>a:hover,.pf-workflow .nav-pills>li.active>a:focus {background:linear-gradient(135deg,#134e38 0%,#0c3424 100%);color:white;border-color:#092d1f;box-shadow:0 3px 10px rgba(12,52,36,.28)}

      /* Module Action Toolbar */
      .pf-toolbar {display:grid;grid-template-columns:minmax(0,1fr) minmax(220px,auto);align-items:start;gap:18px;padding:16px 18px;background:#f6faf7;border:1px solid #dce8df;border-radius:11px;margin-bottom:12px}
      .pf-toolbar-left {min-width:0;display:flex;flex-direction:column;gap:10px}
      .pf-toolbar-desc {font-size:.86rem;color:#2b4f3d;line-height:1.4}
      .pf-desc-badge {font-weight:750;color:#0e3323}
      .pf-desc-text {color:#436653}
      .pf-toolbar-inputs {display:flex;align-items:end;gap:12px;flex-wrap:wrap}
      .pf-toolbar-inputs .form-group {margin-bottom:0}
      .pf-toolbar-inputs label {font-size:.85rem;font-weight:700;color:#113827;margin-bottom:2px}
      .pf-toolbar-inputs .radio-inline {margin-right:12px;font-size:.85rem;color:#163b2c;font-weight:550}
      .pf-advanced {margin-top:0;padding:8px 12px;border:1px solid #d9e6dd;border-radius:8px;max-width:540px;background:white;font-size:.83rem}
      .pf-advanced summary {cursor:pointer;font-weight:650;color:#18533a}
      .pf-advanced[open] {padding-bottom:8px}
      .pf-advanced .form-group {margin-top:8px;max-width:260px}
      .pf-toolbar-actions {display:flex;align-items:stretch;flex-direction:column;gap:8px;min-width:220px}
      .pf-btn-run {background:linear-gradient(180deg,#10b981 0%,#059669 100%) !important;border:1px solid #047857 !important;color:white !important;border-radius:8px !important;font-weight:750 !important;font-size:.94rem !important;letter-spacing:-.01em !important;padding:8px 22px !important;box-shadow:0 3px 12px rgba(16,185,129,.32) !important;transition:all .15s ease !important;display:inline-flex !important;align-items:center !important;justify-content:center !important;text-align:center !important;gap:7px !important}
      .pf-btn-run:hover {background:linear-gradient(180deg,#059669 0%,#047857 100%) !important;box-shadow:0 4px 15px rgba(16,185,129,.45) !important;transform:translateY(-1px)}
      .pf-status {color:#395d4a;font-size:.78rem;font-weight:650;text-align:center;min-height:1.5em}
      .pf-hint-box {background:#f2f8f4;border:1px dashed #c6ded0;border-radius:7px;padding:7px 11px;font-size:.83rem;color:#2c543f}

      /* Legal / Botanical Alert Callout */
      .pf-alert-info {background:#f0f6fb;border-left:3.5px solid #2980b9;border-radius:6px;padding:7px 14px;margin:6px 0 10px;color:#154564;font-size:.83rem;line-height:1.45;display:flex;align-items:center;gap:9px}
      .pf-alert-icon {font-size:1.05rem;line-height:1}
      .pf-review-alert {background:#fff8e9;border:1px solid #efd49d;border-left:4px solid #bd7b15;border-radius:8px;padding:10px 14px;margin:10px 0;color:#65440e;font-size:.84rem;line-height:1.45}
      .pf-review-alert strong {color:#533606}

      /* Results Section */
      .pf-results {scroll-margin-top:12px}
      .pf-empty {margin-top:10px;background:#fbfdfc;border:1.5px dashed #c4ddd0;border-radius:12px;padding:26px 20px;color:#355a48;text-align:center}
      .pf-empty-icon {font-size:2.0rem;line-height:1;margin-bottom:8px;opacity:.88}
      .pf-empty-title {font-weight:750;font-size:1.02rem;color:#0e3625;margin-bottom:4px;letter-spacing:-.01em}
      .pf-empty-sub {font-size:.86rem;color:#4e6f5e;max-width:500px;margin:auto;line-height:1.45}
      .pf-metrics-grid {display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px;margin:14px 0 18px}
      .pf-kpi-card {background:#fff;border:1px solid #d9e6de;border-radius:10px;padding:13px 15px;box-shadow:0 2px 6px rgba(11,46,35,.025);transition:transform .15s ease}
      .pf-kpi-card:hover {transform:translateY(-1px);box-shadow:0 4px 10px rgba(11,46,35,.06)}
      .pf-kpi-val {font-family:var(--pf-font-sans);font-size:1.4rem;font-weight:800;letter-spacing:-.02em;line-height:1.2;margin-bottom:4px}
      .pf-kpi-lbl {font-size:.72rem;font-weight:700;color:#506d5e;text-transform:uppercase;letter-spacing:.03em;line-height:1.35}
      .pf-card-total .pf-kpi-val {color:#0d3625}.pf-card-total {border-left:4px solid #0d3625}
      .pf-card-success .pf-kpi-val {color:#059669}.pf-card-success {border-left:4px solid #059669;background:#f5fbf7}
      .pf-card-threat .pf-kpi-val {color:#be3426}.pf-card-threat {border-left:4px solid #be3426;background:#fdf6f5}
      .pf-card-cites .pf-kpi-val {color:#cb4f00}.pf-card-cites {border-left:4px solid #cb4f00;background:#fef8f4}
      .pf-card-endemic .pf-kpi-val {color:#0b826f}.pf-card-endemic {border-left:4px solid #0b826f;background:#f1f9f7}
      .pf-card-warning .pf-kpi-val {color:#cc8009}.pf-card-warning {border-left:4px solid #cc8009;background:#fdfbf4}
      .pf-card-danger .pf-kpi-val {color:#962d22}.pf-card-danger {border-left:4px solid #962d22;background:#fdf5f5}
      .pf-card-muted .pf-kpi-val {color:#768485}.pf-card-muted {border-left:4px solid #bcc2c6;background:#fafbfa}
      .pf-table-help {display:flex;align-items:center;justify-content:space-between;gap:12px;margin:4px 0 8px;color:#40614f;font-size:.81rem}
      .pf-table-help strong {color:#173d2a;font-size:.9rem}
      .pf-results .dataTables_wrapper {margin-top:8px;font-size:.85rem;font-family:var(--pf-font-sans)}
      .pf-results .dataTables_scroll {border:1px solid #dce8df;border-radius:10px;overflow:hidden}
      .pf-results .dataTables_scrollBody {background:#fff}
      .pf-results table.dataTable thead th {background:#eef5f1;color:#103927;font-weight:750;font-size:.74rem;letter-spacing:.025em;text-transform:uppercase;border-bottom:2px solid #c9ded2 !important;min-width:110px;white-space:normal}
      .pf-results table.dataTable tbody td {color:#143124;padding:10px 12px;white-space:nowrap}
      .pf-results table.dataTable tbody tr:nth-child(even) {background:#f9fbf9}
      .pf-results table.dataTable tbody tr:hover {background-color:#f4faf6 !important}
      .pf-downloads-container {margin-top:12px;display:flex;align-items:center;gap:10px;flex-wrap:wrap}
      .pf-btn-download {background:#ffffff !important;color:#154a37 !important;border:1.5px solid #1f674c !important;border-radius:7px !important;font-weight:700 !important;font-size:.85rem !important;padding:6.5px 15px !important;transition:all .15s ease !important}
      .pf-btn-download:hover {background:#edf6f1 !important;color:#0c2f22 !important;border-color:#134734 !important;transform:translateY(-1px);box-shadow:0 3px 8px rgba(19,71,52,.12)}
      .pf-btn-xlsx {background:#f3f9f5 !important;border-color:#2b792f !important;color:#195b1d !important}
      .pf-btn-xlsx:hover {background:#e4f3ea !important;color:#103f14 !important}

      /* Detail View Card */
      .pf-detail-card {margin-top:14px}
      .pf-detail-header {display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;border-bottom:1px solid #ebf1ed;padding-bottom:8px}
      .pf-detail-header h3 {margin:0;font-size:1.12rem;font-weight:750;color:#0e3625;letter-spacing:-.015em}
      .pf-detail-row-idx {background:#e7f3ec;color:#19533b;font-weight:700;font-size:.79rem;border-radius:6px;padding:2px 8px}
      .pf-results dl {display:grid;grid-template-columns:minmax(140px,1fr) 2fr;gap:6px 18px;font-size:.87rem}
      .pf-results dt {color:#3d604e;font-weight:700}
      .pf-results dd {margin:0;overflow-wrap:anywhere;color:#102c1f;font-weight:500}

      /* References Footer Card */
      .pf-references-card {margin-top:16px;background:#fcfdfc;border:1px solid #d9e5dc}
      .pf-references-card summary {cursor:pointer;font-weight:680;color:#0f3827;display:flex;align-items:center;justify-content:space-between;font-size:.90rem}
      .pf-ref-title {font-weight:750;font-size:.94rem;color:#0e3625}
      .pf-ref-grid {display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:12px;margin-top:12px}
      .pf-ref-item {background:#f6faf7;border:1px solid #dfe9e2;border-radius:8px;padding:12px}
      .pf-ref-item h4 {font-size:.89rem;font-weight:750;color:#0e3625;margin:0 0 5px;letter-spacing:-.01em}
      .pf-ref-item p {font-size:.81rem;color:#4c6a5a;margin:0;line-height:1.45}

      .pf-workflow a:focus-visible,.pf-module-card button:focus-visible,
      .pf-card button:focus-visible,.pf-card summary:focus-visible,
      .pf-module-card summary:focus-visible,.pf-results a:focus-visible {
        outline:3px solid #10b981;outline-offset:3px;
      }
      @media (prefers-reduced-motion: reduce) {
        .pf-workflow a,.pf-btn-run,.pf-btn-download,.pf-kpi-card {transition:none !important;transform:none !important}
      }

      @media(max-width:850px){
        .container-fluid{padding:10px}
        .pf-navbar{flex-direction:column;align-items:flex-start;padding:12px 14px;gap:8px}
        .pf-brand-sub{display:none}
        .pf-card,.pf-module-card{padding:12px}
        .pf-inputs{grid-template-columns:1fr;gap:12px}
        .pf-upload{border-left:0;border-top:1px solid #e4ece6;padding:12px 0 0}
        .pf-toolbar{grid-template-columns:1fr}
        .pf-toolbar-actions{min-width:0;align-items:flex-start}
        .pf-status{text-align:left}
        .pf-workflow .nav-pills{flex-wrap:nowrap;overflow-x:auto;white-space:nowrap;padding-bottom:6px}
      }
      @media(max-width:480px){
        .pf-nav-brand{min-width:0}
        .pf-brand-title{font-size:1.2rem}
        .pf-brand-tag{font-size:.64rem}
        .pf-nav-badges{gap:4px}
        .pf-nav-badge{font-size:.68rem;padding:3px 6px}
        .pf-section-heading{align-items:flex-start;flex-direction:column}
        .pf-input-actions{width:100%;flex-wrap:wrap}
        .pf-toolbar-actions{align-items:stretch}
        .pf-btn-run{justify-content:center !important}
        .pf-results dl{grid-template-columns:1fr;gap:2px}
        .pf-results dd{margin-bottom:8px}
      }
    "))),
    shiny::div(class = "pf-navbar",
      shiny::div(class = "pf-nav-brand",
        shiny::tags$span(class = "pf-nav-logo", title = "peruflora - Flora silvestre del Per\u00FA",
          shiny::HTML('<svg class="pf-nav-svg" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>')
        ),
        shiny::div(
          shiny::tags$span(class = "pf-brand-title", "peruflora"),
          shiny::tags$span(class = "pf-brand-tag", "v0.1.0"),
          shiny::tags$span(class = "pf-brand-sub", "Reconciliaci\u00F3n y armonizaci\u00F3n taxon\u00F3mica de flora silvestre del Per\u00FA")
        )
      ),
      shiny::div(class = "pf-nav-badges",
        shiny::tags$span(class = "pf-nav-badge", "CITES Flora 2018"),
        shiny::tags$span(class = "pf-nav-badge", "WCVP V-16 (ppendemic)"),
        shiny::tags$span(class = "pf-nav-badge", "Libro Rojo 2006 (redbookperu)"),
        shiny::tags$span(class = "pf-nav-badge", "D.S. 043-2006-AG (peruflorads43)")
      )
    ),
    shiny::div(class = "pf-card",
      shiny::div(class = "pf-section-heading",
        shiny::div(class = "pf-heading-left",
          shiny::tags$span(class = "pf-step", "1"),
          shiny::tags$h2("Nombres para consultar")
        ),
        shiny::div(class = "pf-input-actions",
          shiny::actionButton("sample", "Usar ejemplo", class = "btn pf-btn-subtle pf-btn-sm"),
          shiny::actionButton("clear", "Limpiar todo", class = "btn pf-btn-subtle pf-btn-clear pf-btn-sm")
        )
      ),
      shiny::div(class = "pf-inputs",
        shiny::div(class = "pf-input-col",
          shiny::tags$label(`for` = "names_text", class = "pf-input-col-title", "Escribe o pega nombres cient\u00EDficos"),
          shiny::textAreaInput("names_text", label = NULL, width = "100%",
            value = "",
            height = "112px",
            placeholder = "Swietenia macrophylla\nAa aurantiaca\nSanchezia ovata\nCattleya maxima\nPersea americana"),
          shiny::div(class = "pf-input-footer-row",
            shiny::div(class = "pf-count-badge",
              shiny::tags$span(class = "pf-count-dot"),
              shiny::textOutput("input_count", inline = TRUE)
            ),
            shiny::tags$span(class = "pf-hint", "Un nombre por l\u00EDnea")
          )
        ),
        shiny::div(class = "pf-upload",
          shiny::tags$label(`for` = "file", class = "pf-input-col-title", "Carga un archivo de datos"),
          shiny::fileInput("file", label = NULL,
            buttonLabel = "Examinar archivo...", placeholder = "Ning\u00FAn archivo seleccionado",
            accept = c(".txt", ".csv", ".tsv", ".xls", ".xlsx")),
          shiny::tags$div(class = "pf-formats-bar",
            "Formatos: ",
            shiny::tags$span(class = "pf-format-pill", "CSV"),
            shiny::tags$span(class = "pf-format-pill", "XLSX"),
            shiny::tags$span(class = "pf-format-pill", "TSV"),
            shiny::tags$span(class = "pf-format-pill", "TXT"),
            shiny::tags$span(class = "pf-hint-inline", " \u00B7 Si tambi\u00E9n pegas nombres, se suman al archivo")
          ),
          shiny::conditionalPanel("input.file && input.file.name",
            shiny::div(class = "pf-file-settings",
              shiny::checkboxInput("header", "La primera fila contiene encabezados", TRUE),
              shiny::selectInput("column", "Columna de nombres cient\u00EDficos", choices = NULL),
              shiny::textOutput("file_message")
            ),
            shiny::tags$details(class = "pf-file-preview",
              shiny::tags$summary("Vista previa del archivo cargado"), DT::DTOutput("preview"))
          )
        )
      )
    ),
    shiny::div(class = "pf-workflow",
      shiny::div(class = "pf-section-heading",
        shiny::div(class = "pf-heading-left",
          shiny::tags$span(class = "pf-step", "2"),
          shiny::tags$h2("Elige la consulta")
        )
      ),
      shiny::tabsetPanel(id = "module", type = "pills",
        shiny::tabPanel("Consulta integrada", value = "integrada",
          app_module_ui("integrada", "integrada", "Consulta integrada",
            "Cruza CITES Flora, endemismo WCVP, Libro Rojo y D.S. 043 en una sola vista.")),
        shiny::tabPanel("CITES Flora", value = "cites",
          app_module_ui("cites", "cites", "CITES Flora Per\u00FA",
            "Consulta ap\u00E9ndices y estatus en el listado MINAM (2018).")),
        shiny::tabPanel("Endemismo actual", value = "endemismo",
          app_module_ui("endemismo", "endemismo", "Endemismo actual (WCVP)",
            "Consulta condici\u00F3n de endemismo con ppendemic (WCVP V-16).")),
        shiny::tabPanel("Libro Rojo", value = "libro_rojo",
          app_module_ui("libro_rojo", "libro_rojo", "Libro Rojo de Plantas End\u00E9micas",
            "Consulta el Libro Rojo hist\u00F3rico (2006) y categor\u00EDas UICN t\u00E9cnicas.")),
        shiny::tabPanel("D.S. 043-2006-AG", value = "ds043",
          app_module_ui("ds043", "ds043", "Flora Silvestre Amenazada (D.S. 043)",
            "Verifica categor\u00EDas legales oficiales de protecci\u00F3n en el Per\u00FA."))
      )
    ),
    shiny::div(class = "pf-card pf-references-card",
      shiny::tags$details(
        shiny::tags$summary(
          shiny::tags$span(class = "pf-ref-title", "\U0001F4DA Fuentes oficiales y marco normativo"),
          shiny::tags$span(class = "pf-hint", "Checklists taxon\u00F3micos y marcos regulatorios de flora del Per\u00FA")
        ),
        shiny::div(class = "pf-ref-grid",
          shiny::div(class = "pf-ref-item",
            shiny::tags$h4("CITES Flora Per\u00FA (citesperu)"),
            shiny::tags$p("Listado oficial de flora silvestre protegida por la Convenci\u00F3n CITES en el Per\u00FA (MINAM 2018, 2506 taxones). Clasifica en Ap\u00E9ndices I, II y III.")
          ),
          shiny::div(class = "pf-ref-item",
            shiny::tags$h4("Endemismo Actual (ppendemic)"),
            shiny::tags$p("Cat\u00E1logo taxon\u00F3mico de taxones end\u00E9micos del Per\u00FA basado en World Checklist of Vascular Plants (WCVP V-16, >8000 registros).")
          ),
          shiny::div(class = "pf-ref-item",
            shiny::tags$h4("Libro Rojo de Plantas End\u00E9micas (redbookperu)"),
            shiny::tags$p("Publicaci\u00F3n de Le\u00F3n et al. (2006) en Revista Peruana de Biolog\u00EDa, con categor\u00EDas UICN hist\u00F3ricas y actualizaci\u00F3n taxon\u00F3mica.")
          ),
          shiny::div(class = "pf-ref-item",
            shiny::tags$h4("Flora Amenazada D.S. 043 (peruflorads43)"),
            shiny::tags$p("Decreto Supremo N\u00B0 043-2006-AG (especies de flora legalmente amenazadas: CR, EN, VU, NT), con reconciliaci\u00F3n de nombres originales y actuales.")
          )
        )
      )
    )
  )
}

app_module_settings <- function(input, module) {
  switch(module,
    integrada = list(
      view = input$view,
      modo = input$modo
    ),
    cites = list(
      edition = input$edition,
      distance = input$distance,
      synonyms = if (is.null(input$synonyms)) TRUE else isTRUE(input$synonyms),
      genus = if (is.null(input$genus)) FALSE else isTRUE(input$genus)
    ),
    endemismo = list(
      distance = input$distance
    ),
    libro_rojo = list(
      distance = input$distance
    ),
    ds043 = list()
  )
}

app_module_summary_cards <- function(value, module) {
  if (is.null(value) || !nrow(value)) return(NULL)
  n_total <- if ("indice_entrada" %in% names(value)) {
    length(unique(value$indice_entrada))
  } else {
    nrow(value)
  }

  cards <- switch(module,
    integrada = {
      n_cites <- if ("cites_apendice" %in% names(value)) {
        sum(!is.na(value$cites_apendice) & nzchar(as.character(value$cites_apendice)), na.rm = TRUE)
      } else if ("status_fuente" %in% names(value) && "fuente" %in% names(value)) {
        sum(value$fuente == "cites" & !is.na(value$status_fuente) & nzchar(value$status_fuente), na.rm = TRUE)
      } else 0L

      n_endemic <- if ("endemismo_actual" %in% names(value)) {
        sum(value$endemismo_actual == TRUE, na.rm = TRUE)
      } else if ("status_fuente" %in% names(value) && "fuente" %in% names(value)) {
        sum(value$fuente == "endemismo_actual" & value$presencia == TRUE, na.rm = TRUE)
      } else 0L

      n_redbook <- if ("libro_rojo_endemico" %in% names(value)) {
        sum(value$libro_rojo_endemico == TRUE, na.rm = TRUE)
      } else if ("status_fuente" %in% names(value) && "fuente" %in% names(value)) {
        sum(value$fuente == "libro_rojo" & value$presencia == TRUE, na.rm = TRUE)
      } else 0L

      n_ds043 <- if ("ds043_categoria" %in% names(value)) {
        sum(!is.na(value$ds043_categoria) & nzchar(as.character(value$ds043_categoria)), na.rm = TRUE)
      } else if ("status_fuente" %in% names(value) && "fuente" %in% names(value)) {
        sum(value$fuente == "ds043" & !is.na(value$status_fuente) & nzchar(value$status_fuente), na.rm = TRUE)
      } else 0L

      n_review <- if ("review_flag" %in% names(value)) {
        sum(value$review_flag == TRUE, na.rm = TRUE)
      } else if ("requiere_revision" %in% names(value)) {
        sum(value$requiere_revision == TRUE, na.rm = TRUE)
      } else 0L

      list(
        list(label = "Total consultados", value = n_total, class = "pf-card-total"),
        list(label = "Listados en CITES Flora", value = sprintf("%d (%.1f%%)", n_cites, 100 * n_cites / n_total), class = "pf-card-cites"),
        list(label = "End\u00E9micos actuales (WCVP)", value = sprintf("%d (%.1f%%)", n_endemic, 100 * n_endemic / n_total), class = "pf-card-endemic"),
        list(label = "En Libro Rojo (2006)", value = sprintf("%d (%.1f%%)", n_redbook, 100 * n_redbook / n_total), class = "pf-card-warning"),
        list(label = "Amenazados D.S. 043-2006-AG", value = sprintf("%d (%.1f%%)", n_ds043, 100 * n_ds043 / n_total), class = "pf-card-threat"),
        list(label = "Requieren revisi\u00F3n", value = sprintf("%d (%.1f%%)", n_review, 100 * n_review / n_total), class = "pf-card-danger")
      )
    },
    cites = {
      n_cites <- if ("is_cites" %in% names(value)) sum(value$is_cites == TRUE, na.rm = TRUE) else 0L
      n_app1 <- if ("apendice" %in% names(value)) sum(grepl("I($|[^I])", as.character(value$apendice)), na.rm = TRUE) else 0L
      n_app23 <- if ("apendice" %in% names(value)) sum(grepl("II|III", as.character(value$apendice)), na.rm = TRUE) else 0L
      list(
        list(label = "Total consultados", value = n_total, class = "pf-card-total"),
        list(label = "Coincidencias CITES", value = sprintf("%d (%.1f%%)", n_cites, 100 * n_cites / n_total), class = "pf-card-cites"),
        list(label = "Ap\u00E9ndice I (M\u00E1xima restricci\u00F3n)", value = n_app1, class = "pf-card-threat"),
        list(label = "Ap\u00E9ndice II o III", value = n_app23, class = "pf-card-warning")
      )
    },
    endemismo = {
      n_endemic <- if ("Endemic.Tag" %in% names(value)) {
        sum(value$Endemic.Tag == "Endemic", na.rm = TRUE)
      } else if ("matched" %in% names(value)) {
        sum(value$matched == TRUE, na.rm = TRUE)
      } else 0L
      n_direct <- if ("direct_match" %in% names(value)) sum(value$direct_match == TRUE, na.rm = TRUE) else 0L
      n_fuzzy <- n_endemic - n_direct
      list(
        list(label = "Total consultados", value = n_total, class = "pf-card-total"),
        list(label = "End\u00E9micos del Per\u00FA (WCVP)", value = sprintf("%d (%.1f%%)", n_endemic, 100 * n_endemic / n_total), class = "pf-card-endemic"),
        list(label = "Coincidencias directas", value = sprintf("%d (%.1f%%)", n_direct, 100 * n_direct / n_total), class = "pf-card-success"),
        list(label = "Coincidencias aproximadas", value = sprintf("%d (%.1f%%)", n_fuzzy, 100 * n_fuzzy / n_total), class = "pf-card-warning")
      )
    },
    libro_rojo = {
      n_matched <- if ("match_status" %in% names(value)) sum(!value$match_status %in% c("no_match", "none", NA), na.rm = TRUE) else 0L
      n_exact <- if ("match_status" %in% names(value)) sum(value$match_status == "exact", na.rm = TRUE) else 0L
      n_fuzzy <- if ("match_status" %in% names(value)) sum(value$match_status %in% c("fuzzy", "ambiguous"), na.rm = TRUE) else 0L
      list(
        list(label = "Total consultados", value = n_total, class = "pf-card-total"),
        list(label = "En Libro Rojo (2006)", value = sprintf("%d (%.1f%%)", n_matched, 100 * n_matched / n_total), class = "pf-card-warning"),
        list(label = "Coincidencias exactas", value = sprintf("%d (%.1f%%)", n_exact, 100 * n_exact / n_total), class = "pf-card-success"),
        list(label = "Aproximadas / Ambiguas", value = sprintf("%d (%.1f%%)", n_fuzzy, 100 * n_fuzzy / n_total), class = "pf-card-danger")
      )
    },
    ds043 = {
      n_ds043 <- if ("Protected.DS043" %in% names(value)) sum(value$Protected.DS043 == TRUE, na.rm = TRUE) else 0L
      n_cr_en <- if ("Consolidated.Category" %in% names(value)) {
        sum(value$Consolidated.Category %in% c("CR", "EN", "Peligro Cr\u00EDtico", "En Peligro"), na.rm = TRUE)
      } else 0L
      n_vu_nt <- if ("Consolidated.Category" %in% names(value)) {
        sum(value$Consolidated.Category %in% c("VU", "NT", "Vulnerable", "Casi Amenazado"), na.rm = TRUE)
      } else 0L
      list(
        list(label = "Total consultados", value = n_total, class = "pf-card-total"),
        list(label = "En D.S. 043-2006-AG", value = sprintf("%d (%.1f%%)", n_ds043, 100 * n_ds043 / n_total), class = "pf-card-threat"),
        list(label = "Peligro Cr\u00EDtico (CR) / En Peligro (EN)", value = n_cr_en, class = "pf-card-danger"),
        list(label = "Vulnerable (VU) / Casi Amenazado (NT)", value = n_vu_nt, class = "pf-card-warning")
      )
    }
  )

  shiny::div(class = "pf-metrics-grid",
    lapply(cards, function(card) {
      shiny::div(class = paste("pf-kpi-card", card$class),
        shiny::div(class = "pf-kpi-val", card$value),
        shiny::div(class = "pf-kpi-lbl", card$label)
      )
    })
  )
}

app_module_server <- function(id, module, records) {
  force(id)
  force(module)
  shiny::moduleServer(id, function(input, output, session) {
    result <- shiny::reactiveVal(NULL)
    running <- shiny::reactiveVal(FALSE)
    status <- shiny::reactiveVal("Ingresa nombres y pulsa el bot\u00F3n de esta consulta.")
    job <- NULL
    generation <- 0L
    settings <- shiny::reactive(app_module_settings(input, module))
    cancel <- function(message) {
      generation <<- generation + 1L
      if (!is.null(job) && job$is_alive()) job$kill_tree()
      job <<- NULL
      running(FALSE)
      result(NULL)
      status(message)
    }
    shiny::observeEvent(list(records(), settings()), {
      cancel("La entrada o las opciones cambiaron. Vuelve a consultar.")
    }, ignoreInit = TRUE)
    shiny::observeEvent(input$cancel, cancel("Consulta cancelada."), ignoreInit = TRUE)
    session$onSessionEnded(function() {
      if (!is.null(job) && job$is_alive()) job$kill_tree()
    })
    shiny::observeEvent(input$run, {
      cancel("Preparando consulta\u2026")
      input_records <- tryCatch(records(), error = function(e) e)
      if (inherits(input_records, "error")) {
        status(conditionMessage(input_records)); return(invisible(NULL))
      }
      problem <- tryCatch({ app_validate_records(input_records); NULL },
                          error = function(e) conditionMessage(e))
      if (!is.null(problem)) { status(problem); return(invisible(NULL)) }
      current_settings <- settings()
      can_async <- isTRUE(getOption("peruflora.async", TRUE)) &&
        requireNamespace("callr", quietly = TRUE) &&
        requireNamespace("later", quietly = TRUE)

      if (can_async) {
        package_path <- getNamespaceInfo(asNamespace("peruflora"), "path")
        libs <- .libPaths()
        if (dir.exists(file.path(package_path, ".cran-lib"))) {
          libs <- unique(c(normalizePath(file.path(package_path, ".cran-lib")), libs))
        }
        job <<- tryCatch(callr::r_bg(
          function(path, libs, module, records, settings) {
            .libPaths(libs)
            if (file.exists(file.path(path, "R", "flora-match.R")) &&
                requireNamespace("pkgload", quietly = TRUE)) {
              pkgload::load_all(path, helpers = FALSE, quiet = TRUE)
            } else {
              library("peruflora", lib.loc = dirname(path), character.only = TRUE)
            }
            ns <- asNamespace("peruflora")
            value <- get("app_query", ns)(module, records$submitted_name, settings)
            get("app_result_with_source", ns)(value, records)
          },
          args = list(path = package_path, libs = libs, module = module,
                      records = input_records, settings = current_settings),
          supervise = TRUE
        ), error = function(e) e)

        if (!inherits(job, "error")) {
          token <- generation
          running(TRUE)
          status(paste("Consultando", nrow(input_records), "nombres\u2026"))
          poll <- function() {
            if (token != generation || session$isClosed() || is.null(job)) return(invisible(NULL))
            if (job$is_alive()) {
              later::later(poll, 0.2)
            } else {
              value <- tryCatch(job$get_result(), error = function(e) e)
              job <<- NULL
              running(FALSE)
              if (inherits(value, "error")) status(conditionMessage(value)) else {
                result(value)
                status(paste("Consulta terminada:", nrow(value), "filas."))
                session$sendCustomMessage("pf-scroll-results", session$ns("results"))
              }
            }
          }
          later::later(poll, 0.2)
          return(invisible(NULL))
        }
        job <<- NULL
      }

      # Modo s\u00EDncrono (respaldo autom\u00E1tico o si peruflora.async es FALSE)
      running(TRUE)
      status(paste("Consultando", nrow(input_records), "nombres\u2026"))
      value <- tryCatch({
        ns <- asNamespace("peruflora")
        res <- get("app_query", ns)(module, input_records$submitted_name, current_settings)
        get("app_result_with_source", ns)(res, input_records)
      }, error = function(e) e)
      running(FALSE)
      if (inherits(value, "error")) {
        status(conditionMessage(value))
      } else {
        result(value)
        status(paste("Consulta terminada:", nrow(value), "filas."))
        session$sendCustomMessage("pf-scroll-results", session$ns("results"))
      }
    })
    output$status <- shiny::renderText(status())
    output$cancel_ui <- shiny::renderUI({
      if (!running()) return(NULL)
      shiny::actionButton(session$ns("cancel"), "Cancelar consulta", class = "btn pf-btn-subtle pf-btn-clear")
    })
    output$summary <- shiny::renderUI({
      value <- result()
      if (is.null(value)) return(shiny::div(class = "pf-empty",
        shiny::tags$div(class = "pf-empty-icon", "\U0001F33F"),
        shiny::tags$div(class = "pf-empty-title", "Listo para consultar"),
        shiny::tags$div(class = "pf-empty-sub",
          "Usa el bot\u00F3n de esta pesta\u00F1a para validar los nombres en la fuente seleccionada.")
      ))
      review_count <- if ("review_flag" %in% names(value)) {
        sum(value$review_flag %in% TRUE)
      } else 0L
      shiny::tagList(
        app_module_summary_cards(value, module),
        if (review_count > 0L) shiny::div(class = "pf-review-alert", role = "status",
          shiny::tags$strong(paste(review_count, "fila(s) requieren revisi\u00F3n manual. ")),
          "Las correcciones aproximadas o ambiguas son propuestas de reconciliaci\u00F3n y requieren validaci\u00F3n bot\u00E1nica antes de utilizarse como categor\u00EDa confirmada."
        )
      )
    })
    output$table_help <- shiny::renderUI({
      if (is.null(result())) return(NULL)
      shiny::div(class = "pf-table-help",
        shiny::tags$strong("Resultados detallados"),
        shiny::tags$span("Despl\u00E1zate horizontalmente para ver todas las columnas; selecciona una fila para ver su detalle."))
    })
    output$table <- DT::renderDT({
      value <- result(); shiny::req(value)
      DT::datatable(value, rownames = FALSE, colnames = app_field_label(base::names(value)),
        selection = "single", filter = "top",
        options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE,
                       language = app_dt_language()))
    })
    output$detail <- shiny::renderUI({
      value <- result(); selected <- input$table_rows_selected
      if (is.null(value) || !length(selected)) return(NULL)
      row <- value[selected[1], , drop = FALSE]
      title_name <- if ("nombre_aceptado" %in% names(row) && !is.na(row$nombre_aceptado[1])) {
        row$nombre_aceptado[1]
      } else if ("nombre_original" %in% names(row) && !is.na(row$nombre_original[1])) {
        row$nombre_original[1]
      } else if ("submitted_name" %in% names(row)) {
        row$submitted_name[1]
      } else "Fila seleccionada"

      shiny::div(class = "pf-card pf-detail-card",
        shiny::div(class = "pf-detail-header",
          shiny::tags$h3(paste("Detalle:", title_name)),
          shiny::tags$span(class = "pf-detail-row-idx", paste("Fila", selected[1]))
        ),
        shiny::tags$dl(lapply(base::names(row), function(nm) {
          val <- row[[nm]][1]
          txt <- if (is.na(val) || is.null(val)) "Sin dato" else if (is.logical(val)) (if (val) "S\u00ED" else "No") else as.character(val)
          shiny::tagList(shiny::tags$dt(app_field_label(nm)), shiny::tags$dd(txt))
        }))
      )
    })
    output$downloads <- shiny::renderUI({
      if (is.null(result())) return(NULL)
      shiny::div(class = "pf-downloads-container",
        shiny::downloadButton(session$ns("csv"), "Descargar CSV", class = "btn pf-btn-download"),
        if (requireNamespace("writexl", quietly = TRUE))
          shiny::downloadButton(session$ns("xlsx"), "Descargar XLSX", class = "btn pf-btn-download pf-btn-xlsx") else
          shiny::tags$span(class = "pf-hint", "Instala writexl para exportar a XLSX."))
    })
    output$csv <- shiny::downloadHandler(
      filename = function() paste0("peruflora-", module, ".csv"),
      content = function(file) utils::write.csv(result(), file, row.names = FALSE,
                                                 fileEncoding = "UTF-8")
    )
    output$xlsx <- shiny::downloadHandler(
      filename = function() paste0("peruflora-", module, ".xlsx"),
      content = function(file) {
        if (!requireNamespace("writexl", quietly = TRUE)) {
          stop("Instala 'writexl' para descargar XLSX.", call. = FALSE)
        }
        writexl::write_xlsx(result(), file)
      }
    )
  })
}

peruflora_app_server <- function(input, output, session) {
  upload <- shiny::reactiveVal(NULL)
  upload_error <- shiny::reactiveVal(NULL)
  shiny::observeEvent(list(input$file, input$header), {
    upload(NULL); upload_error(NULL)
    if (is.null(input$file)) return(invisible(NULL))
    parsed <- tryCatch(app_read_file(input$file$datapath, input$file$name,
                                     header = isTRUE(input$header)),
                       error = function(e) e)
    if (inherits(parsed, "error")) {
      upload_error(conditionMessage(parsed)); return(invisible(NULL))
    }
    upload(parsed)
    shiny::updateSelectInput(session, "column",
                             choices = c("Selecciona una columna" = "", base::names(parsed$data)),
                             selected = app_guess_column(parsed$data))
  })
  shiny::observeEvent(input$sample, {
    shiny::updateTextAreaInput(session, "names_text",
      value = "Swietenia macrophylla\nAa aurantiaca\nSanchezia ovata\nCattleya maxima\nPersea americana")
  })
  shiny::observeEvent(input$clear, {
    upload(NULL); upload_error(NULL)
    shiny::updateTextAreaInput(session, "names_text", value = "")
    shiny::updateSelectInput(session, "column", choices = character())
    session$sendCustomMessage("pf-reset-file", list())
  })
  records <- shiny::reactive({
    if (!is.null(upload_error())) return(simpleError(upload_error()))
    tryCatch(app_records(input$names_text, upload(), input$column),
             error = function(e) e)
  })
  output$file_message <- shiny::renderText({
    if (!is.null(upload_error())) return(upload_error())
    file <- upload()
    if (is.null(file)) "Puedes consultar solo con texto pegado." else
      paste(nrow(file$data), "filas cargadas de", file$name)
  })
  output$input_count <- shiny::renderText({
    value <- records()
    if (inherits(value, "error")) "Revisa el archivo y la columna seleccionada." else
      paste0(format(nrow(value), big.mark = " "), " nombres listos para consultar (m\u00E1x. 10 000)")
  })
  output$preview <- DT::renderDT({
    file <- upload(); if (is.null(file)) return(NULL)
    DT::datatable(utils::head(file$data, 10), rownames = FALSE,
                  options = list(dom = "t", scrollX = TRUE,
                                 language = app_dt_language()))
  })
  app_module_server("integrada", "integrada", records)
  app_module_server("cites", "cites", records)
  app_module_server("endemismo", "endemismo", records)
  app_module_server("libro_rojo", "libro_rojo", records)
  app_module_server("ds043", "ds043", records)
}
