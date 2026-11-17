# peruflora 0.1.0

* Initial release of **`peruflora`**, an R metapackage to cross-reference and harmonize Peruvian flora taxonomy and conservation data across four independent backbones:
  * `citesperu`: Official CITES appendices for Peruvian flora (MINAM 2018 edition, 2506 taxa).
  * `ppendemic`: Accepted endemic taxa of Peru from World Checklist of Vascular Plants (WCVP V-16, >8000 taxa).
  * `redbookperu`: Historical Red Book of Endemic Plants of Peru (León et al., 2006) with updated taxonomic reconciliation and technical IUCN categories.
  * `peruflorads43`: Supreme Decree No. 043-2006-AG, the official national threat categorization for wild flora in Peru (CR, EN, VU, NT), reconciling original and updated nomenclature.

* **Core Functions**:
  * `flora_match()`: Structured long-format tibble returning source-level evidence, provenance, taxonomic evaluation (`"confirmado"`, `"sin_coincidencia"`, `"requiere_revision"`, `"ambiguo"`), match distance, and candidate statuses.
  * `flora_status()`: Compact wide-format summary reporting CITES appendix, current endemism, historical Red Book status, D.S. 043-2006-AG legal category, and a unified `requiere_revision` flag.
  * `flora_fuentes()`: Overview of source editions, metadata, and installed package versions.

* **Interactive Shiny Application**:
  * Added `run_peruflora_app()`, `flora_app()`, and `peruflora_app()` providing an interactive web interface with five views:
    * *Consulta integrada*: Unified multi-source lookup.
    * *CITES Flora*: Specialized CITES query.
    * *Endemismo actual*: WCVP V-16 endemic taxa lookup.
    * *Libro Rojo*: Historical Red Book lookup with IUCN categories.
    * *D.S. 043-2006-AG*: Official legal threat categories.
  * Shared file upload (TXT, CSV with comma/semicolon auto-detection, TSV, XLS, XLSX) and text paste inputs supporting up to 10 000 names per query.
  * Asynchronous query processing via `callr` and `later` with a responsive cancellation button and automatic synchronous fallback.
  * Interactive `DT` tables localized in Spanish with column-level search filters and row detail inspection.
  * Interactive summary KPI cards and visual alert for records requiring manual review.
  * Export results to CSV (UTF-8) and Excel (XLSX via `writexl`).
  * Standalone deployment entrypoints via root `app.R` and `system.file("app", package = "peruflora")` / `system.file("shiny", package = "peruflora")`.

* **Metapackage Orchestration**:
  * `peruflora_attach()`: Clean startup attachment of the four ecosystem packages.
  * `peruflora_deps()`: Diagnostic table of ecosystem dependency installation and version requirements.
  * `peruflora_sitrep()`: Situation report for runtime diagnostics.
  * `peruflora_conflicts()`: S3 conflict detection comparing memory pointers.
