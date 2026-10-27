.ucdp_replication <- "https://ucdp.uu.se/downloads/replication_data.html"

#' List publication-specific UCDP replication files
#'
#' `ucdp_replication_catalog()` reads UCDP's official replication archive,
#' which contains frozen datasets and related materials used in UCDP-authored
#' publications.
#'
#' @param query Optional case-insensitive regular expression matched against
#'   publication, dataset, title, version, and file type.
#' @param year Optional publication year or years.
#' @param type Optional file types such as `"data"`, `"codebook"`,
#'   `"version_history"`, `"appendix"`, or `"other"`.
#' @param quiet Suppress the status message?
#' @return A tibble with one row per downloadable replication artifact.
#' @export
#' @examples
#' \dontrun{
#' catalog <- ucdp_replication_catalog(year = 2025)
#' ucdp_replication_catalog("Georeferenced", type = "data")
#' }
ucdp_replication_catalog <- function(query = NULL, year = NULL, type = NULL,
                                     quiet = FALSE) {
  if (!is.null(query) && (!is.character(query) || length(query) != 1L ||
                          is.na(query) || !nzchar(query))) {
    cli::cli_abort("{.arg query} must be one non-empty regular expression.")
  }
  if (!is.null(year) && (anyNA(year) || !all(grepl("^[0-9]{4}$", as.character(year))))) {
    cli::cli_abort("{.arg year} must contain four-digit years.")
  }
  if (!is.null(type) && (!is.character(type) || anyNA(type) || any(!nzchar(type)))) {
    cli::cli_abort("{.arg type} must contain non-empty file types.")
  }
  if (!quiet) cli::cli_inform("Reading the UCDP replication archive...")
  response <- tryCatch(
    ucdp_request(.ucdp_replication) |> httr2::req_perform(),
    error = function(e) cli::cli_abort(c(
      "Could not read the UCDP replication archive.",
      "i" = conditionMessage(e)
    ), parent = e)
  )
  out <- parse_replication_html(httr2::resp_body_html(response), .ucdp_replication)
  filter_replication_catalog(out, query, year, type)
}

parse_replication_html <- function(page, base = .ucdp_replication) {
  links <- rvest::html_elements(page, "a[href]")
  rows <- lapply(links, function(link) {
    year_node <- rvest::html_element(link, xpath = "preceding::h2[1]")
    year_text <- node_text(year_node)
    if (is.na(year_text) || !grepl("^[0-9]{4}$", year_text)) return(NULL)
    title <- node_text(link)
    href <- rvest::html_attr(link, "href")
    url <- absolute_url(href, base)
    if (is.na(title) || !nzchar(title) || !grepl("^https?://", url) ||
        grepl("doi.org", url, ignore.case = TRUE)) return(NULL)
    publication_node <- rvest::html_element(
      year_node, xpath = "following-sibling::p[normalize-space()][1]"
    )
    data.frame(
      year = as.integer(year_text),
      publication = node_text(publication_node),
      dataset = replication_dataset_name(title, url),
      version = extract_replication_version(paste(title, url)),
      file_type = replication_file_type(title),
      title = title,
      format = infer_format(title, url),
      url = url,
      file_name = basename(sub("[?#].*$", "", url)),
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(empty_replication_catalog())
  out <- unique(do.call(rbind, rows))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

replication_dataset_name <- function(title, url) {
  text <- tolower(paste(title, url))
  rules <- list(
    "ucdp.?prio|armed conflict dataset|ucdp-prio" = "UCDP/PRIO Armed Conflict Dataset",
    "dyadic dataset|/dyadic/" = "UCDP Dyadic Dataset",
    "battle.?related deaths|battledeaths|battlerelated" = "UCDP Battle Related Deaths Dataset",
    "non.?state conflict|nonstate|/nsos/" = "UCDP Non-State Conflict Dataset",
    "one.?sided violence|onesided" = "UCDP One-Sided Violence Dataset",
    "vpp ged|violent political protest ged" = "UCDP Violent Political Protest GED Dataset",
    "georeferenced event|ucdp ged|/ged/" = "UCDP Georeferenced Event Dataset (GED)",
    "peace agreement" = "UCDP Peace Agreement Dataset"
  )
  for (pattern in names(rules)) {
    if (grepl(pattern, text, perl = TRUE)) return(unname(rules[[pattern]]))
  }
  cleaned <- sub("(?i)^(codebook for|version history for)[[:space:]]+", "", title, perl = TRUE)
  cleaned <- sub("(?i)[[:space:]]+v\\.?[[:space:]]*[0-9].*$", "", cleaned, perl = TRUE)
  cleaned <- clean_text(cleaned)
  if (replication_file_type(title) %in% c("appendix", "other")) NA_character_ else cleaned
}

extract_replication_version <- function(x) {
  match <- regexec(
    "(?i)(?:version|v\\.?)[[:space:]]*([0-9]+(?:[.-][0-9A-Za-z]+)+)",
    x, perl = TRUE
  )
  hit <- regmatches(x, match)[[1L]]
  if (length(hit) < 2L) return(extract_version(x))
  sub("[.,;:]$", "", hit[[2L]])
}

replication_file_type <- function(title) {
  if (grepl("version history", title, ignore.case = TRUE)) return("version_history")
  if (grepl("codebook", title, ignore.case = TRUE)) return("codebook")
  if (grepl("appendix|supplement|dataset note|fixes", title, ignore.case = TRUE)) return("appendix")
  if (grepl("dataset|GED|data", title, ignore.case = TRUE)) return("data")
  "other"
}

empty_replication_catalog <- function() {
  tibble::tibble(
    year = integer(), publication = character(), dataset = character(),
    version = character(), file_type = character(), title = character(),
    format = character(), url = character(), file_name = character()
  )
}

filter_replication_catalog <- function(catalog, query = NULL, year = NULL,
                                       type = NULL) {
  out <- catalog
  if (!is.null(query)) {
    fields <- c("publication", "dataset", "title", "version", "file_type")
    haystack <- apply(out[fields], 1L, paste, collapse = " ")
    out <- out[grepl(query, haystack, ignore.case = TRUE), , drop = FALSE]
  }
  if (!is.null(year)) out <- out[out$year %in% as.integer(year), , drop = FALSE]
  if (!is.null(type)) out <- out[out$file_type %in% type, , drop = FALSE]
  out
}

#' Download files from the UCDP replication archive
#'
#' @param dataset Dataset name, alias, or regular expression.
#' @param version Optional exact dataset version.
#' @param year Optional publication year or years.
#' @param type File type to select. Defaults to frozen data files.
#' @param query Optional additional regular expression matched by
#'   [ucdp_replication_catalog()].
#' @param variant Optional regular expression matched against artifact titles.
#' @param download_all Download every match? Otherwise ambiguous requests fail.
#' @param dest_dir Destination directory.
#' @param overwrite Replace existing files?
#' @param quiet Suppress messages?
#' @param catalog Optional pre-fetched replication catalog.
#' @return A normalized character vector of downloaded paths, invisibly, with
#'   catalog records, checksums, retrieval time, and package version attached.
#' @export
#' @examples
#' \dontrun{
#' ucdp_replication_download("ged", version = "25.1")
#' }
ucdp_replication_download <- function(dataset, version = NULL, year = NULL,
                                      type = "data", query = NULL,
                                      variant = NULL, download_all = FALSE,
                                      dest_dir = "replication",
                                      overwrite = FALSE, quiet = FALSE,
                                      catalog = NULL) {
  if (!is.logical(download_all) || length(download_all) != 1L || is.na(download_all)) {
    cli::cli_abort("{.arg download_all} must be TRUE or FALSE.")
  }
  if (is.null(catalog)) catalog <- ucdp_replication_catalog(quiet = quiet)
  choices <- filter_replication_catalog(catalog, query, year, type)
  choices <- choices[grepl(resolve_alias(dataset), ifelse(is.na(choices$dataset), "", choices$dataset),
                           ignore.case = TRUE), , drop = FALSE]
  if (!is.null(version)) {
    choices <- choices[!is.na(choices$version) &
                         choices$version == as.character(version), , drop = FALSE]
  }
  if (!is.null(variant)) {
    choices <- choices[grepl(variant, choices$title, ignore.case = TRUE), , drop = FALSE]
  }
  choices <- choices[!duplicated(choices$url), , drop = FALSE]
  if (!nrow(choices)) cli::cli_abort("No matching UCDP replication file was found.")
  if (nrow(choices) > 1L && !download_all) {
    cli::cli_abort(c(
      "The request matches more than one replication file.",
      "i" = paste(choices$title, collapse = "; "),
      "i" = "Refine the request or set {.arg download_all = TRUE}."
    ))
  }
  download_archive_records(choices, dest_dir, overwrite, quiet)
}

download_archive_records <- function(records, dest_dir, overwrite, quiet) {
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- character(nrow(records))
  checksums <- character(nrow(records))
  for (i in seq_len(nrow(records))) {
    file_name <- records$file_name[[i]]
    if (is.na(file_name) || !nzchar(file_name)) {
      extension <- if (records$format[[i]] == "other") "file" else records$format[[i]]
      file_name <- paste0(safe_name(records$title[[i]]), ".", extension)
    }
    destination <- file.path(dest_dir, file_name)
    if (file.exists(destination) && !overwrite) {
      cli::cli_abort(c(
        "File already exists: {.path {destination}}",
        "i" = "Set {.arg overwrite = TRUE} to replace it."
      ))
    }
    if (!quiet) cli::cli_inform("Downloading {.field {records$title[[i]]}} to {.path {destination}}...")
    tryCatch(
      ucdp_request(records$url[[i]]) |> httr2::req_perform(path = destination),
      error = function(e) {
        if (file.exists(destination)) unlink(destination)
        cli::cli_abort(c(
          "A UCDP archive file could not be downloaded.",
          "i" = conditionMessage(e)
        ), parent = e)
      }
    )
    if (!file.exists(destination) || file.info(destination)$size == 0) {
      cli::cli_abort("The downloaded archive file is empty or missing.")
    }
    paths[[i]] <- normalizePath(destination, winslash = "/", mustWork = TRUE)
    checksums[[i]] <- unname(tools::md5sum(paths[[i]]))
  }
  attr(paths, "ucdp_records") <- records
  attr(paths, "md5") <- checksums
  attr(paths, "retrieved_at") <- ucdp_timestamp()
  attr(paths, "ucdpR_version") <- ucdp_package_version()
  invisible(paths)
}

#' Download an official UCDP version history
#'
#' @param dataset Dataset name or alias.
#' @param version Optional exact release identifier.
#' @param dest_dir Destination directory.
#' @param overwrite Replace an existing file?
#' @param open Open the downloaded file with the system viewer?
#' @param quiet Suppress messages?
#' @param catalog Optional pre-fetched version-history catalog, primarily for
#'   reproducible or offline use.
#' @return The normalized downloaded path, invisibly, with provenance
#'   attributes.
#' @export
#' @examples
#' \dontrun{ucdp_version_history("prio", version = "25.1")}
ucdp_version_history <- function(dataset, version = NULL,
                                 dest_dir = "documentation",
                                 overwrite = FALSE, open = FALSE,
                                 quiet = FALSE, catalog = NULL) {
  if (!is.logical(open) || length(open) != 1L || is.na(open)) {
    cli::cli_abort("{.arg open} must be TRUE or FALSE.")
  }
  if (is.null(catalog)) {
    catalog <- version_history_catalog(
      include_historical = !is.null(version), quiet = quiet
    )
  }
  choices <- catalog[grepl(resolve_alias(dataset), catalog$dataset, ignore.case = TRUE), , drop = FALSE]
  if (!is.null(version)) {
    choices <- choices[!is.na(choices$version) &
                         choices$version == as.character(version), , drop = FALSE]
  }
  choices <- choices[!duplicated(choices$url), , drop = FALSE]
  if (!nrow(choices)) cli::cli_abort("No matching UCDP version history was found.")
  if (nrow(choices) > 1L) {
    cli::cli_abort(c(
      "The request matches more than one version history.",
      "i" = paste0(choices$dataset, " [v", choices$version, "]", collapse = "; "),
      "i" = "Specify an exact {.arg version}."
    ))
  }
  path <- download_archive_records(choices, dest_dir, overwrite, quiet)
  if (open) utils::browseURL(path[[1L]])
  invisible(path)
}

version_history_catalog <- function(include_historical = FALSE, quiet = FALSE) {
  pages <- c(current = .ucdp_base)
  if (include_historical) pages <- c(pages, historical = .ucdp_history)
  parts <- lapply(names(pages), function(source) {
    if (!quiet) cli::cli_inform("Reading UCDP {.val {source}} version histories...")
    response <- tryCatch(
      ucdp_request(pages[[source]]) |> httr2::req_perform(),
      error = function(e) cli::cli_abort(c(
        "Could not read UCDP {.val {source}} version histories.",
        "i" = conditionMessage(e)
      ), parent = e)
    )
    parse_version_history_html(httr2::resp_body_html(response), pages[[source]], source)
  })
  out <- unique(do.call(rbind, parts))
  rownames(out) <- NULL
  tibble::as_tibble(out)
}

parse_version_history_html <- function(page, base, source = "current") {
  links <- rvest::html_elements(page, "a[href]")
  links <- links[grepl("version history", vapply(links, node_text, character(1)),
                      ignore.case = TRUE)]
  if (!length(links)) return(empty_version_history_catalog())
  rows <- lapply(links, function(link) {
    title <- node_text(link)
    url <- absolute_url(rvest::html_attr(link, "href"), base)
    heading <- rvest::html_element(link, xpath = "preceding::*[self::h2 or self::h3][1]")
    dataset <- canonical_dataset(node_text(heading), url)
    parent <- xml2::xml_parent(link)
    preceding <- rvest::html_element(parent, xpath = "preceding-sibling::*[1]")
    context <- paste(title, url, node_text(parent), node_text(preceding), node_text(heading))
    data.frame(
      dataset = sub("[[:space:]]+[Vv]ersion[[:space:]].*$", "", dataset),
      version = extract_replication_version(context),
      file_type = "version_history",
      title = title,
      format = infer_format(title, url),
      url = url,
      file_name = basename(sub("[?#].*$", "", url)),
      source = source,
      stringsAsFactors = FALSE
    )
  })
  tibble::as_tibble(unique(do.call(rbind, rows)))
}

empty_version_history_catalog <- function() {
  tibble::tibble(
    dataset = character(), version = character(), file_type = character(),
    title = character(), format = character(), url = character(),
    file_name = character(), source = character()
  )
}
