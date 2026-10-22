#' List files in the official UCDP download catalog
#'
#' `ucdp_catalog()` reads the official download page each time it is called,
#' so newly released datasets can be discovered without a package update.
#'
#' @param include_documentation Include codebooks and other documentation?
#' @param include_historical Also inspect UCDP's historical-download page? This
#'   adds earlier annual releases and archived monthly Candidate releases.
#' @param quiet Suppress status messages?
#' @return A tibble with one row per downloadable file.
#' @export
#' @examples
#' \dontrun{
#' catalog <- ucdp_catalog()
#' catalog[catalog$format == "csv", ]
#' }
ucdp_catalog <- function(include_documentation = FALSE,
                         include_historical = FALSE,
                         quiet = FALSE) {
  stopifnot(is.logical(include_documentation), length(include_documentation) == 1L,
            is.logical(include_historical), length(include_historical) == 1L)
  pages <- c(current = .ucdp_base)
  if (isTRUE(include_historical)) pages <- c(pages, historical = .ucdp_history)

  out <- lapply(names(pages), function(source) {
    if (!quiet) cli::cli_inform("Reading the UCDP {.val {source}} catalog...")
    parse_catalog_page(pages[[source]], source)
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out <- tibble::as_tibble(out)
  if (!include_documentation) {
    out <- out[out$format != "documentation", , drop = FALSE]
  }
  out
}

parse_catalog_page <- function(url, source = "current") {
  response <- tryCatch(
    ucdp_request(url) |> httr2::req_perform(),
    error = function(e) cli::cli_abort(
      c("Could not read the UCDP download catalog.", "i" = conditionMessage(e)),
      parent = e
    )
  )
  page <- httr2::resp_body_html(response)
  links <- rvest::html_elements(page, "a[href]")
  if (!length(links)) return(empty_catalog())

  rows <- lapply(links, function(link) {
    label <- clean_text(xml2::xml_text(link))
    href <- rvest::html_attr(link, "href")
    # UCDP has used both h2 and h3 for dataset titles. Selecting the nearest
    # preceding heading makes discovery robust to either page structure.
    heading_xpath <- "preceding::*[self::h2 or self::h3][1]"
    heading_node <- rvest::html_element(link, xpath = heading_xpath)
    section_node <- if (identical(source, "historical")) {
      heading_node
    } else {
      rvest::html_element(link, xpath = "preceding::h2[1]")
    }
    dataset <- node_text(heading_node)
    section <- node_text(section_node)
    full_url <- absolute_url(href, url)
    dataset <- canonical_dataset(dataset, full_url)
    parent_node <- xml2::xml_parent(link)
    preceding_node <- rvest::html_element(parent_node, xpath = "preceding-sibling::*[1]")
    context <- paste(label, full_url, node_text(parent_node),
                     node_text(preceding_node), dataset)
    format <- infer_format(label, full_url)
    if (is.na(dataset) || !nzchar(dataset) || !grepl("^https?://", full_url) ||
        format == "other" || grepl("doi.org|sciencedirect|diva-portal|prio.org", full_url)) {
      return(NULL)
    }
    version <- extract_version(context)
    variant <- infer_variant(label, context)
    data.frame(
      dataset = sub("[[:space:]]+[Vv]ersion[[:space:]].*$", "", dataset),
      version = version,
      variant = variant,
      section = section,
      format = format,
      url = full_url,
      file_name = basename(sub("[?#].*$", "", full_url)),
      source = source,
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(empty_catalog())
  unique(do.call(rbind, rows))
}

canonical_dataset <- function(dataset, url) {
  generic <- is.na(dataset) || !nzchar(dataset) || grepl(
    "^(Disaggregated Event Datasets|Yearly Datasets|Other UCDP Datasets|UCDP Dataset Download Center)",
    dataset
  )
  if (!generic) return(dataset)

  path <- tolower(url)
  rules <- list(
    "candidateged" = "UCDP Candidate Events Dataset (UCDP Candidate)",
    "/ged/" = "UCDP Georeferenced Event Dataset (GED)",
    "armedconflict|ucdp.?prio|ucdp-prio" = "UCDP/PRIO Armed Conflict Dataset",
    "/dyadic/|dyadicdataset" = "UCDP Dyadic Dataset",
    "/nonstate/|non-state" = "UCDP Non-State Conflict Dataset",
    "/onesided/|one-sided" = "UCDP One-Sided Violence Dataset",
    "/battlerelated/|battle-related|/brd/" = "UCDP Battle Related Deaths Dataset",
    "/actor/|actordataset" = "UCDP Actor Dataset",
    "/onset/" = "UCDP Onset Dataset",
    "organizedviolencecy" = "UCDP Country-Year Dataset on Organized Violence within Country Borders"
  )
  for (pattern in names(rules)) {
    if (grepl(pattern, path, perl = TRUE)) return(unname(rules[[pattern]]))
  }
  dataset
}

node_text <- function(node) {
  if (inherits(node, "xml_missing") || length(node) == 0L) return(NA_character_)
  # xml_text() deliberately ignores CSS display rules. UCDP's page uses
  # one-letter markup elements that html_text2() may treat as hidden, causing
  # every lower-case n, r, and t in some headings to disappear.
  clean_text(xml2::xml_text(node))
}

infer_variant <- function(label, context) {
  simple <- tolower(label) %in% c("csv", "excel", "stata", "r", "codebook")
  if (!simple) {
    candidate <- sub("(?i)\\s*(csv|excel|stata|r|codebook)\\s*$", "", label, perl = TRUE)
    candidate <- clean_text(gsub("^[|: -]+|[|: -]+$", "", candidate))
    if (nzchar(candidate) && !grepl("^[0-9]+(?:[.-][0-9A-Za-z]+)+$", candidate)) {
      return(candidate)
    }
  }
  if (grepl("dyadic", context, ignore.case = TRUE)) return("dyadic level")
  if (grepl("conflict level|conflict-level", context, ignore.case = TRUE)) return("conflict level")
  NA_character_
}

#' Search the UCDP catalog
#'
#' @param query A case-insensitive regular expression matched against dataset,
#'   variant, version, and section names.
#' @param catalog A catalog returned by [ucdp_catalog()]. If omitted, the
#'   current catalog is downloaded.
#' @param ... Passed to [ucdp_catalog()] when `catalog` is omitted.
#' @return A filtered catalog tibble.
#' @export
#' @examples
#' \dontrun{ucdp_search("georeferenced|GED")}
ucdp_search <- function(query, catalog = NULL, ...) {
  if (!is.character(query) || length(query) != 1L || !nzchar(query)) {
    cli::cli_abort("{.arg query} must be one non-empty character string.")
  }
  if (is.null(catalog)) catalog <- ucdp_catalog(...)
  haystack <- apply(catalog[c("dataset", "variant", "version", "section")], 1L,
                    paste, collapse = " ")
  catalog[grepl(query, haystack, ignore.case = TRUE), , drop = FALSE]
}

#' List available releases of a UCDP dataset
#'
#' @param dataset Dataset name, alias, or regular expression.
#' @param format Optional format to retain, such as `"csv"` or `"xlsx"`.
#' @param include_documentation Include codebooks and documentation?
#' @param quiet Suppress catalog messages?
#' @param catalog Optional catalog containing historical releases. When omitted,
#'   [ucdp_catalog()] is called with `include_historical = TRUE`.
#' @return A catalog tibble sorted from newer to older releases where possible.
#' @export
#' @examples
#' \dontrun{
#' ucdp_versions("ged", format = "csv")
#' ucdp_versions("candidate", format = "csv")
#' }
ucdp_versions <- function(dataset, format = NULL,
                          include_documentation = FALSE, quiet = FALSE,
                          catalog = NULL) {
  if (is.null(catalog)) {
    catalog <- ucdp_catalog(
      include_documentation = include_documentation,
      include_historical = TRUE,
      quiet = quiet
    )
  }
  out <- ucdp_search(resolve_alias(dataset), catalog = catalog)
  if (!is.null(format)) out <- out[out$format %in% tolower(format), , drop = FALSE]
  if (!nrow(out)) cli::cli_abort("No releases matching {.val {dataset}} were found.")
  key <- numeric_version_key(out$version)
  out[order(key, decreasing = TRUE, na.last = TRUE), , drop = FALSE]
}

numeric_version_key <- function(x) {
  vapply(x, function(one) {
    if (is.na(one)) return(NA_real_)
    matches <- regmatches(one, gregexpr("[0-9]+", one))[[1L]]
    if (!length(matches)) return(NA_real_)
    bits <- utils::head(as.numeric(matches), 5L)
    sum(bits / c(1, 1e2, 1e4, 1e6, 1e8)[seq_along(bits)])
  }, numeric(1))
}

