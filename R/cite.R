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
#' \dontrun{ucdp_cite("ged")}
ucdp_cite <- function(dataset, quiet = FALSE) {
  if (!quiet) cli::cli_inform("Reading citation guidance from UCDP...")
  response <- ucdp_request(.ucdp_base) |> httr2::req_perform()
  page <- httr2::resp_body_html(response)
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
  if (is.na(start)) return(character())
  unique(txt[seq.int(start, length(txt))][nzchar(txt[seq.int(start, length(txt))])])
}

#' Check whether a downloaded UCDP file has a newer catalog version
#'
#' @param version The version used in an analysis.
#' @param dataset Dataset name or alias.
#' @param catalog Optional current catalog.
#' @return A one-row tibble with the supplied and current versions and a
#'   logical `update_available` value.
#' @export
ucdp_update_available <- function(dataset, version, catalog = NULL) {
  if (is.null(catalog)) catalog <- ucdp_catalog(quiet = TRUE)
  x <- ucdp_search(resolve_alias(dataset), catalog)
  versions <- unique(stats::na.omit(x$version))
  if (!length(versions)) cli::cli_abort("No version information was found for {.val {dataset}}.")
  current <- versions[[1L]]
  tibble::tibble(dataset = dataset, installed_version = as.character(version),
                 current_version = current,
                 update_available = !identical(as.character(version), current))
}

