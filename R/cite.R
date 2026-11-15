#' Retrieve citation guidance for a UCDP dataset
#'
#' This function extracts the citation block displayed below a dataset on the
#' official UCDP download page. Always report the dataset version in your own
#' work and consult the downloaded codebook for dataset-specific guidance.
#'
#' @param dataset Dataset name or alias.
#' @param quiet Suppress status messages?
#' @return A character vector containing the citation guidance.
#' @export
#' @examples
#' \dontrun{
#' # Citation guidance is read from the live UCDP download page.
#' ucdp_cite("ged")
#' }
ucdp_cite <- function(dataset, quiet = FALSE) {
  if (!quiet) cli::cli_inform("Reading citation guidance from UCDP...")
  response <- tryCatch(
    ucdp_request(.ucdp_base) |> httr2::req_perform(),
    error = function(e) cli::cli_abort(
      c(
        "Could not retrieve UCDP citation guidance.",
        "i" = conditionMessage(e)
      ),
      parent = e
    )
  )
  page <- httr2::resp_body_html(response)
  extract_ucdp_citation(page, dataset)
}

extract_ucdp_citation <- function(page, dataset) {
  headings <- rvest::html_elements(page, "h2, h3")
  query <- resolve_alias(dataset)
  heading_text <- vapply(headings, node_text, character(1))
  hit <- headings[grepl(query, heading_text, ignore.case = TRUE)]
  if (!length(hit)) cli::cli_abort("No dataset matching {.val {dataset}} was found.")
  if (length(hit) > 1L) cli::cli_abort("More than one dataset matches {.val {dataset}}; use a more specific name.")
  nodes <- rvest::html_elements(hit, xpath = "following-sibling::*")
  next_heading <- which(xml2::xml_name(nodes) %in% c("h2", "h3"))[1L]
  if (!is.na(next_heading)) nodes <- nodes[seq_len(next_heading - 1L)]
  txt <- vapply(nodes, node_text, character(1))
  start <- which(grepl("Please cite", txt, ignore.case = TRUE))[1L]
  if (is.na(start)) {
    cli::cli_abort(c(
      "Citation guidance could not be extracted for this dataset.",
      "i" = "The UCDP download-page structure or citation wording may have changed.",
      "i" = "Consult the official dataset codebook or UCDP download page: {.url {(.ucdp_base)}}"
    ))
  }
  unique(txt[seq.int(start, length(txt))][nzchar(txt[seq.int(start, length(txt))])])
}

#' Check whether a downloaded UCDP file has a newer catalog version
#'
#' @param version The version used in an analysis.
#' @param dataset Dataset name or alias.
#' @param variant Optional regular expression used to select a dataset variant.
#' @param format Optional file format used to identify the relevant release
#'   series.
#' @param catalog Optional current catalog.
#' @return A one-row tibble with the supplied and current versions and a
#'   logical `update_available` value.
#' @export
#' @examples
#' catalog <- tibble::tibble(
#'   dataset = "UCDP Georeferenced Event Dataset (GED)", version = "25.1",
#'   variant = NA_character_, section = "Disaggregated Event Datasets",
#'   format = "csv", url = "https://example.org/ged.csv",
#'   file_name = "ged.csv", source = "current"
#' )
#' ucdp_update_available("ged", version = "24.1", catalog = catalog)
ucdp_update_available <- function(dataset, version, variant = NULL,
                                  format = NULL, catalog = NULL) {
  if (length(version) != 1L || is.na(version) || !nzchar(as.character(version))) {
    cli::cli_abort("{.arg version} must be one non-empty version identifier.")
  }
  if (is.null(catalog)) catalog <- ucdp_catalog(quiet = TRUE)
  x <- ucdp_search(resolve_alias(dataset), catalog)
  if (!is.null(variant)) {
    x <- x[grepl(
      variant, ifelse(is.na(x$variant), "", x$variant),
      ignore.case = TRUE
    ), , drop = FALSE]
  }
  if (!is.null(format)) {
    if (!is.character(format) || !length(format) || anyNA(format) ||
        any(!nzchar(format))) {
      cli::cli_abort("{.arg format} must contain one or more non-empty format names.")
    }
    x <- x[x$format %in% tolower(format), , drop = FALSE]
  }
  if ("source" %in% names(x) && any(x$source == "current", na.rm = TRUE)) {
    x <- x[!is.na(x$source) & x$source == "current", , drop = FALSE]
  }
  versions <- unique(stats::na.omit(normalize_version_id(x$version)))
  if (!length(versions)) cli::cli_abort("No version information was found for {.val {dataset}}.")
  keys <- numeric_version_key(versions)
  current <- if (any(!is.na(keys))) {
    versions[[which.max(keys)]]
  } else {
    sort(versions, decreasing = TRUE)[[1L]]
  }
  installed <- normalize_version_id(version)
  tibble::tibble(dataset = dataset, installed_version = as.character(version),
                 current_version = current,
                 update_available = !identical(installed, current))
}

