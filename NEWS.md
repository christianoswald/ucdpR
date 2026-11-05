# ucdpR 0.6.0

* Added `ucdp_aggregate()` for event counts and fatality-bound aggregation at
  country, PRIO-GRID, conflict, and dyad units with yearly or monthly periods.
* Added `ucdp_panel()` to construct complete analytical panels from raw or
  aggregated data. Inserted combinations are explicitly identified as
  zero-filled or missing and never silently presented as observed groups.
* Added `ucdp_fatalities()` to summarize low, best, and high UCDP fatality
  estimates with completeness diagnostics and configurable missing-value
  behavior.
* Expanded tests, examples, README guidance, and the reproducible-research
  vignette for aggregation and panel workflows.

# ucdpR 0.5.1

* Added four focused vignettes covering data access and versioning, spatial
  workflows, uncertainty and revisions, and reproducible research.
* Reworked the getting-started vignette into a concise package overview.
* Expanded help-page examples for every exported function, using runnable
  synthetic data and catalogs wherever the function does not require network
  access or file downloads.

# ucdpR 0.5.0

* Added `ucdp_as_sf()` for provenance-preserving conversion of georeferenced
  UCDP data to optional `sf` point objects.
* Added `ucdp_precision()` and `ucdp_filter_precision()` to describe and filter
  GED spatial and temporal precision codes.
* Added `ucdp_version_history()` to retrieve official current or historical
  dataset version histories.
* Added `ucdp_replication_catalog()` and `ucdp_replication_download()` for
  publication-specific frozen data, codebooks, version histories, and
  supplementary files in UCDP's official replication archive.
* Added `ucdp_schema()` to inspect variable classes, missingness, uniqueness,
  ranges, examples, and attached provenance.
* Added `sf` as an optional dependency and excluded the default local
  `replication/` download directory from builds and version control.

# ucdpR 0.4.1

* Excluded the suggested local `documentation/` download directory from source
  builds and version control so saved codebooks do not trigger an `R CMD check`
  NOTE.

# ucdpR 0.4.0

* Added `ucdp_metadata()` to summarize dataset provenance, dimensions, temporal
  coverage, and coordinate coverage from imported objects, downloaded paths,
  or catalog records.
* Added `ucdp_codebook()` to locate and download official UCDP codebooks,
  including exact-version safeguards and support for documentation variants.
* Added `ucdp_validate()` with structured diagnostics for observation keys,
  dates, fatality estimates, coordinates, and selected UCDP codes.
* New downloads now retain retrieval time and the `ucdpR` package version in
  addition to the catalog record, dataset version, and checksum.

# ucdpR 0.3.4

* Reframed the package documentation around reproducible UCDP research
  workflows and present and future convenience functions, rather than data
  downloading alone.
* Expanded the README and introductory vignette with a dedicated release-
  comparison workflow and clearer guidance on package scope and direction.

# ucdpR 0.3.3

* Corrected the synthetic HTML fixture used to test catalog text extraction.
  The fixture now spells "Yearly Datasets" correctly while retaining the
  nested-element structure that guards against dropped letters.

# ucdpR 0.3.2

* Corrected `clean_text()`: its former regular expression removed the literal
  lower-case letters `n`, `r`, and `t` under R's default regex engine. Whitespace
  normalization now relies solely on the portable POSIX space class.
* Documented the `print()` and `summary()` methods separately so their method
  arguments no longer produce an `R CMD check` warning.

# ucdpR 0.3.1

* Fixed catalog titles losing lower-case `n`, `r`, and `t` characters because
  CSS-aware text extraction treated UCDP's one-letter markup as hidden.
* Restricted URL-based canonical naming to genuine fallback cases, preventing
  auxiliary datasets from being relabeled as similarly named core datasets.
* Applied the same robust text extraction to citation discovery.

# ucdpR 0.3.0

* Added `ucdp_compare_versions()` to audit retrospective changes between two
  downloaded or preloaded UCDP releases. It reports schema changes and added,
  removed, modified, and unchanged observations, with optional cell-level
  details and numeric tolerance.

# ucdpR 0.2.3

* CSV imports now detect type-guessing failures and automatically re-read with
  full-file inference. This correctly treats occasionally comma-separated UCDP
  identifier fields as character without slowing every import by default.
* Explicit `readr` controls such as `col_types` and `guess_max` remain honored.

# ucdpR 0.2.2

* Removed a non-ASCII character from executable R code.
* Qualified `utils::head()` for clean static code analysis.
* Excluded development-only files from the CRAN source archive.

# ucdpR 0.2.1

* Fixed live catalog discovery after UCDP served dataset headings at a
  different HTML level than the rendered page suggested.
* Fixed the multiple-match diagnostic so it includes a stable headline and
  can be tested reliably.

# ucdpR 0.2.0

* Historical releases are now discovered from UCDP's dedicated archive.
* Added `ucdp_versions()` to inspect downloadable versions before selection.
* `version` now supports annual and monthly Candidate release identifiers.
* Downloads and imported objects retain source, version, and checksum metadata.
* Improved detection of historical dyadic and conflict-level variants.

# ucdpR 0.1.0

* Initial release.
* Added live catalog discovery, search, download, import, citation, and update
  checking helpers.

