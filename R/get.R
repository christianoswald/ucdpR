#' Download and import a UCDP dataset
#'
#' @inheritParams ucdp_download
#' @param ... Additional arguments passed to the relevant reader (`readr`,
#'   `readxl`, or `haven`).
#' @param keep_file Keep the downloaded file? The default stores it in a
#'   temporary directory and removes it after import.
#' @return An imported data object. CSV files return a tibble; Excel and Stata
#'   files return the objects produced by `readxl` and `haven`.
#' @export
#' @examples
#' \dontrun{
#' ged <- ucdp_get("ged", format = "csv")
#' }
ucdp_get <- function(dataset, format = "csv", variant = NULL, version = NULL,
                     dest_dir = tempdir(), overwrite = TRUE,
                     include_historical = !is.null(version), quiet = FALSE,
                     catalog = NULL, ..., keep_file = FALSE) {
  path <- ucdp_download(
    dataset = dataset, format = format, variant = variant, version = version,
    dest_dir = dest_dir, overwrite = overwrite,
    include_historical = include_historical, quiet = quiet, catalog = catalog
  )
  provenance <- attributes(path)[c(
    "ucdp_record", "ucdp_version", "md5", "retrieved_at", "ucdpR_version"
  )]
  original_path <- path
  if (!keep_file) on.exit(unlink(original_path), add = TRUE)
  ext <- tolower(tools::file_ext(path))
  if (ext == "zip") {
    unpack_dir <- tempfile("ucdpR-")
    dir.create(unpack_dir)
    on.exit(unlink(unpack_dir, recursive = TRUE), add = TRUE)
    members <- utils::unzip(path, list = TRUE)$Name
    supported <- members[grepl("\\.(csv|xlsx?|dta|rds|rda|rdata)$", members, ignore.case = TRUE)]
    supported <- supported[!grepl("(^|/)(__MACOSX|\\.)", supported)]
    if (!length(supported)) cli::cli_abort("The archive does not contain a supported tabular file.")
    if (length(supported) > 1L) {
      requested <- if (tolower(format) == "any") "" else tolower(format)
      ext_pattern <- switch(requested, csv = "\\.csv$", xlsx = "\\.xlsx?$",
                            dta = "\\.dta$", rdata = "\\.(rdata|rda)$",
                            rds = "\\.rds$", "")
      matching <- supported[grepl(ext_pattern, supported, ignore.case = TRUE)]
      if (length(matching) == 1L) supported <- matching
    }
    if (length(supported) != 1L) {
      cli::cli_abort(c("The archive contains several supported data files." = supported,
                       "i" = "Use {.fn ucdp_download} and select a file manually."))
    }
    utils::unzip(path, files = supported, exdir = unpack_dir)
    path <- file.path(unpack_dir, supported)
    ext <- tolower(tools::file_ext(path))
  }
  result <- switch(ext,
    csv = {
      require_reader("readr", "CSV")
      read_ucdp_csv(path, ...)
    },
    xls =, xlsx = {
      require_reader("readxl", "Excel")
      readxl::read_excel(path, ...)
    },
    dta = {
      require_reader("haven", "Stata")
      haven::read_dta(path, ...)
    },
    rds = readRDS(path),
    rda =, rdata = read_rdata(path),
    cli::cli_abort("Automatic import is not supported for {.file {basename(path)}}; use {.fn ucdp_download} instead.")
  )
  attr(result, "ucdp_source") <- provenance
  result
}

read_ucdp_csv <- function(path, ...) {
  dots <- list(...)
  user_controls_types <- any(c("col_types", "guess_max") %in% names(dots))
  args <- c(list(file = path), dots)
  if (!"show_col_types" %in% names(dots)) args$show_col_types <- FALSE

  if (user_controls_types) return(do.call(readr::read_csv, args))

  # UCDP identifier columns may contain a single numeric-looking ID in most
  # rows and comma-separated IDs in a few later rows. Try readr's fast default
  # inference first, then inspect its recorded parsing problems and re-read
  # with complete type inference only when necessary.
  result <- suppressWarnings(do.call(readr::read_csv, args))
  if (!nrow(readr::problems(result))) return(result)

  args$guess_max <- Inf
  do.call(readr::read_csv, args)
}

require_reader <- function(package, label) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cli::cli_abort("Install the {.pkg {package}} package to import {label} files.")
  }
}

read_rdata <- function(path) {
  environment <- new.env(parent = emptyenv())
  objects <- load(path, envir = environment)
  values <- mget(objects, envir = environment, inherits = FALSE)
  if (length(values) == 1L) values[[1L]] else values
}

