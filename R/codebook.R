#' Download an official UCDP codebook
#'
#' `ucdp_codebook()` locates documentation listed with a dataset in UCDP's
#' official download catalog. When an exact historical version is requested,
#' the function returns only documentation explicitly associated with that
#' version; it never silently substitutes the current codebook.
#'
#' @param dataset Dataset name or alias.
#' @param version Optional exact release identifier.
#' @param variant Optional regular expression used to distinguish documentation
#'   variants.
#' @param dest_dir Destination directory.
#' @param overwrite Replace an existing file?
#' @param open Open the downloaded codebook with the system viewer?
#' @param quiet Suppress catalog and download messages?
#' @param catalog Optional catalog created with
#'   `ucdp_catalog(include_documentation = TRUE)`.
#' @return The normalized path to the downloaded codebook, invisibly. The path
#'   carries the selected catalog record, version, checksum, retrieval time,
#'   and package version as attributes.
#' @export
#' @examples
#' \dontrun{
#' path <- ucdp_codebook("ged", dest_dir = "documentation")
#' ucdp_codebook("brd", variant = "dyadic", open = TRUE)
#' }
ucdp_codebook <- function(dataset, version = NULL, variant = NULL,
                          dest_dir = ".", overwrite = FALSE, open = FALSE,
                          quiet = FALSE, catalog = NULL) {
  if (!is.logical(open) || length(open) != 1L || is.na(open)) {
    cli::cli_abort("{.arg open} must be TRUE or FALSE.")
  }
  if (is.null(catalog)) {
    catalog <- ucdp_catalog(
      include_documentation = TRUE,
      include_historical = !is.null(version), quiet = quiet
    )
  }
  choices <- ucdp_search(resolve_alias(dataset), catalog)
  choices <- choices[choices$format == "documentation", , drop = FALSE]
  if (!is.null(version)) {
    choices <- choices[!is.na(choices$version) &
                         choices$version == as.character(version), , drop = FALSE]
  }
  if (!is.null(variant)) {
    choices <- choices[grepl(
      variant, ifelse(is.na(choices$variant), "", choices$variant),
      ignore.case = TRUE
    ), , drop = FALSE]
  }
  choice <- select_codebook_record(choices, dataset, version, variant)

  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  file_name <- choice$file_name[[1L]]
  if (is.na(file_name) || !nzchar(file_name)) {
    file_name <- paste0(safe_name(choice$dataset[[1L]]), "-codebook.pdf")
  }
  destination <- file.path(dest_dir, file_name)
  if (file.exists(destination) && !overwrite) {
    cli::cli_abort(c(
      "File already exists: {.path {destination}}",
      "i" = "Set {.arg overwrite = TRUE} to replace it."
    ))
  }
  if (!quiet) {
    cli::cli_inform("Downloading the codebook for {.field {choice$dataset}} to {.path {destination}}...")
  }
  tryCatch(
    ucdp_request(choice$url[[1L]]) |> httr2::req_perform(path = destination),
    error = function(e) {
      if (file.exists(destination)) unlink(destination)
      cli::cli_abort(c(
        "The UCDP codebook could not be downloaded.",
        "i" = conditionMessage(e)
      ), parent = e)
    }
  )
  if (!file.exists(destination) || file.info(destination)$size == 0) {
    cli::cli_abort("The downloaded codebook is empty or missing.")
  }
  result <- normalizePath(destination, winslash = "/", mustWork = TRUE)
  attr(result, "ucdp_record") <- choice
  attr(result, "ucdp_version") <- choice$version[[1L]]
  attr(result, "md5") <- unname(tools::md5sum(result))
  attr(result, "retrieved_at") <- ucdp_timestamp()
  attr(result, "ucdpR_version") <- ucdp_package_version()
  if (open) utils::browseURL(result)
  invisible(result)
}

select_codebook_record <- function(x, dataset, version, variant) {
  if (nrow(x)) x <- x[!duplicated(x$url), , drop = FALSE]
  if (!nrow(x)) {
    details <- if (is.null(version)) {
      "No codebook is listed for this dataset in the UCDP catalog."
    } else {
      paste0("No codebook explicitly associated with version ", version,
             " is listed; the current codebook was not substituted.")
    }
    cli::cli_abort(c(
      "No matching UCDP codebook was found.",
      "i" = details
    ))
  }
  if (nrow(x) > 1L) {
    labels <- paste0(
      x$dataset,
      ifelse(is.na(x$variant), "", paste0(" -- ", x$variant)),
      " [v", ifelse(is.na(x$version), "?", x$version), "]"
    )
    cli::cli_abort(c(
      "The request matches more than one codebook.",
      "i" = paste(labels, collapse = "; "),
      "i" = "Refine {.arg dataset}, {.arg variant}, or {.arg version}."
    ))
  }
  x[1L, , drop = FALSE]
}
