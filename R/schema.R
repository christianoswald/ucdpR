#' Inspect the structure of a UCDP dataset
#'
#' `ucdp_schema()` reports storage classes, missingness, uniqueness, ranges,
#' and example values. It accepts an existing data frame or a dataset name that
#' can be passed to [ucdp_get()].
#'
#' @param x A data frame, or a dataset name or alias.
#' @param version,variant,format,quiet Passed to [ucdp_get()] when `x` is a
#'   dataset name.
#' @param ... Additional arguments passed to [ucdp_get()].
#' @return A tibble with one row per variable. Its `ucdp_metadata` attribute
#'   contains a provenance summary for the inspected data.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:3, year = c(2020, 2021, NA), country = c("A", "A", "B")
#' )
#' schema <- ucdp_schema(events)
#' schema[c("variable", "class", "pct_missing", "n_unique")]
#' \dontrun{ucdp_schema("ged", version = "25.1")}
ucdp_schema <- function(x, version = NULL, variant = NULL, format = "csv",
                        quiet = FALSE, ...) {
  if (is.character(x)) {
    if (length(x) != 1L || is.na(x) || !nzchar(x)) {
      cli::cli_abort("{.arg x} must be one dataset name or a data frame.")
    }
    x <- ucdp_get(
      x, version = version, variant = variant, format = format,
      quiet = quiet, ...
    )
  }
  if (!is.data.frame(x)) cli::cli_abort("{.arg x} must be a data frame or dataset name.")
  rows <- lapply(names(x), function(name) schema_variable(x[[name]], name))
  out <- tibble::as_tibble(do.call(rbind, rows))
  attr(out, "ucdp_metadata") <- ucdp_metadata(x)
  out
}

schema_variable <- function(x, name) {
  missing <- is.na(x)
  observed <- x[!missing]
  class_name <- paste(class(x), collapse = "/")
  unique_n <- if (is.atomic(x) || is.factor(x)) length(unique(observed)) else NA_integer_
  range <- schema_range(observed)
  example <- schema_examples(observed)
  data.frame(
    variable = name,
    class = class_name,
    storage_type = typeof(x),
    n_missing = sum(missing),
    pct_missing = if (length(x)) sum(missing) / length(x) else NA_real_,
    n_unique = unique_n,
    minimum = range[[1L]],
    maximum = range[[2L]],
    examples = example,
    stringsAsFactors = FALSE
  )
}

schema_range <- function(x) {
  if (!length(x)) return(c(NA_character_, NA_character_))
  if (is.numeric(x) || inherits(x, c("Date", "POSIXct", "POSIXlt"))) {
    value <- range(x, na.rm = TRUE)
    return(as.character(value))
  }
  c(NA_character_, NA_character_)
}

schema_examples <- function(x, n = 3L) {
  if (!length(x)) return(NA_character_)
  if (is.list(x) && !is.data.frame(x)) return(paste0("<", class(x)[[1L]], ">"))
  values <- unique(as.character(x))
  paste(utils::head(values, n), collapse = " | ")
}
