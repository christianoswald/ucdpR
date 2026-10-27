#' Download an official UCDP data file
#'
#' @param dataset Dataset name, alias, or regular expression. Use
#'   [ucdp_search()] to inspect matches. Common aliases include `ged`,
#'   `candidate`, `prio`, `dyadic`, `nonstate`, `onesided`, `brd`, and `actor`.
#' @param format Preferred format, including `"csv"`, `"xlsx"`, `"dta"`,
#'   `"rdata"`, `"sql"`, `"shapefile"`, `"geojson"`, or `"any"`.
#' @param variant Optional regular expression used to select among variants
#'   such as dyadic/conflict-level BRD files or onset datasets.
#' @param version Optional exact UCDP version, for example `"24.1"` or
#'   `"25.0.12"`. Supplying a version automatically searches the historical
#'   catalog. Use [ucdp_versions()] to inspect downloadable releases.
#' @param dest_dir Destination directory. It is created when necessary.
#' @param overwrite Replace an existing file?
#' @param include_historical Search the historical-download page too?
#' @param quiet Suppress messages and download progress?
#' @param catalog Optional pre-fetched catalog, useful for repeated downloads.
#' @return The normalized path to the downloaded file, invisibly.
#' @export
#' @examples
#' \dontrun{
#' # Pin a release and retain the original file for reproducibility.
#' path <- ucdp_download(
#'   "ged", version = "25.1", format = "csv", dest_dir = "data-raw"
#' )
#' attr(path, "ucdp_version")
#' attr(path, "md5")
#' }
ucdp_download <- function(dataset, format = "csv", variant = NULL,
                          version = NULL, dest_dir = ".", overwrite = FALSE,
                          include_historical = !is.null(version), quiet = FALSE,
                          catalog = NULL) {
  format <- match.arg(tolower(format), c(
    "csv", "xlsx", "dta", "rdata", "rds", "sql", "shapefile",
    "geojson", "kml", "shx", "zip", "any"
  ))
  if (is.null(catalog)) {
    catalog <- ucdp_catalog(include_historical = include_historical, quiet = quiet)
  }
  query <- resolve_alias(dataset)
  choices <- ucdp_search(query, catalog = catalog)
  if (format != "any") choices <- choices[choices$format == format, , drop = FALSE]
  if (!is.null(version)) {
    version <- as.character(version)
    choices <- choices[!is.na(choices$version) & choices$version == version, , drop = FALSE]
  }
  if (!is.null(variant)) {
    choices <- choices[grepl(variant, ifelse(is.na(choices$variant), "", choices$variant),
                             ignore.case = TRUE), , drop = FALSE]
  }
  choice <- select_one(choices, dataset, format, variant, version)
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  destination <- file.path(dest_dir, choice$file_name)
  if (file.exists(destination) && !overwrite) {
    cli::cli_abort(c("File already exists: {.path {destination}}",
                     "i" = "Set {.arg overwrite = TRUE} to replace it."))
  }
  if (!quiet) cli::cli_inform("Downloading {.field {choice$dataset}} to {.path {destination}}...")
  response <- tryCatch(
    ucdp_request(choice$url) |> httr2::req_perform(path = destination),
    error = function(e) {
      if (file.exists(destination)) unlink(destination)
      cli::cli_abort(c("The UCDP file could not be downloaded.", "i" = conditionMessage(e)), parent = e)
    }
  )
  if (!file.exists(destination) || file.info(destination)$size == 0) {
    cli::cli_abort("The downloaded file is empty or missing.")
  }
  result <- normalizePath(destination, winslash = "/", mustWork = TRUE)
  attr(result, "ucdp_record") <- choice
  attr(result, "ucdp_version") <- choice$version[[1L]]
  attr(result, "md5") <- unname(tools::md5sum(result))
  attr(result, "retrieved_at") <- ucdp_timestamp()
  attr(result, "ucdpR_version") <- ucdp_package_version()
  invisible(result)
}

resolve_alias <- function(x) {
  aliases <- c(
    ged = "Georeferenced Event Dataset", candidate = "Candidate Events",
    prio = "UCDP/PRIO Armed Conflict", armedconflict = "UCDP/PRIO Armed Conflict",
    dyadic = "UCDP Dyadic Dataset", nonstate = "Non-State Conflict Dataset",
    onesided = "One-sided Violence Dataset", brd = "Battle[- ]Related Deaths",
    actor = "UCDP Actor Dataset", onset = "UCDP Onset Dataset",
    protest = "Violent Political Protest", peace = "Peace Agreement Dataset"
  )
  key <- tolower(gsub("[-_ ]", "", x))
  if (key %in% names(aliases)) unname(aliases[[key]]) else x
}

select_one <- function(x, dataset, format, variant, version) {
  if (!nrow(x)) {
    cli::cli_abort(c("No matching UCDP file was found.",
      "i" = "Use {.fn ucdp_search} to see available dataset names and formats."))
  }
  if (nrow(x) > 1L) {
    labels <- paste0(x$dataset, ifelse(is.na(x$variant), "", paste0(" -- ", x$variant)),
                     " [", x$format, ", v", ifelse(is.na(x$version), "?", x$version), "]")
    cli::cli_abort(c(
      "The request matches more than one file.",
      "i" = paste(labels, collapse = "; "),
      "i" = "Refine {.arg dataset}, {.arg variant}, or {.arg version}."
    ))
  }
  x[1L, , drop = FALSE]
}

