#' Compare two releases of a UCDP dataset
#'
#' `ucdp_compare_versions()` identifies observations and values that were added,
#' removed, or revised between two UCDP releases. It can download both releases
#' or compare data frames that have already been imported.
#'
#' @param dataset Dataset name or alias accepted by [ucdp_get()].
#' @param old_version,new_version Exact release identifiers.
#' @param variant Optional dataset variant, such as `"dyadic"`.
#' @param format Download format. CSV is recommended for stable comparisons.
#' @param key Character vector of columns that uniquely identify observations.
#'   When `NULL`, a key is inferred and verified for uniqueness in both data
#'   sets.
#' @param columns Columns whose values should be compared. The default compares
#'   all columns shared by the releases except key and ignored columns.
#' @param ignore Columns to exclude from value comparisons. The release-level
#'   `version` column is ignored by default because it necessarily differs.
#' @param tolerance Relative tolerance for comparisons between numeric values.
#' @param detail Return `"rows"` (the default), cell-level changes with
#'   `"cells"`, or only summaries with `"summary"`.
#' @param old_data,new_data Optional preloaded data frames. Supply both or
#'   neither. This is useful when releases have already been downloaded.
#' @param quiet Suppress download messages?
#' @param ... Additional arguments passed to [ucdp_get()] for both releases.
#'
#' @return An object of class `ucdp_version_comparison`. Its components include
#'   `overview`, `variables`, `added`, `removed`, `modified`, `cell_changes`,
#'   and `metadata`.
#' @export
#' @examples
#' old <- data.frame(id = 1:3, deaths = c(1, 2, 3), version = "1.0")
#' new <- data.frame(id = 2:4, deaths = c(2, 4, 1), version = "2.0")
#' comparison <- ucdp_compare_versions(
#'   "ged", "1.0", "2.0", key = "id",
#'   old_data = old, new_data = new
#' )
#' comparison$overview
#'
#' \dontrun{
#' comparison <- ucdp_compare_versions("ged", "24.1", "25.1")
#' comparison$modified
#' }
ucdp_compare_versions <- function(dataset, old_version, new_version,
                                  variant = NULL, format = "csv", key = NULL,
                                  columns = NULL, ignore = "version",
                                  tolerance = sqrt(.Machine$double.eps),
                                  detail = c("rows", "cells", "summary"),
                                  old_data = NULL, new_data = NULL,
                                  quiet = FALSE, ...) {
  detail <- match.arg(detail)
  validate_comparison_inputs(dataset, old_version, new_version, tolerance,
                             old_data, new_data)

  supplied <- !is.null(old_data)
  if (!supplied) {
    catalog <- ucdp_catalog(include_historical = TRUE, quiet = quiet)
    old_data <- ucdp_get(
      dataset, version = old_version, variant = variant, format = format,
      catalog = catalog, quiet = quiet, ...
    )
    new_data <- ucdp_get(
      dataset, version = new_version, variant = variant, format = format,
      catalog = catalog, quiet = quiet, ...
    )
  }

  old_data <- as.data.frame(old_data, stringsAsFactors = FALSE)
  new_data <- as.data.frame(new_data, stringsAsFactors = FALSE)
  key <- resolve_comparison_key(old_data, new_data, key)
  validate_comparison_key(old_data, new_data, key)

  old_names <- names(old_data)
  new_names <- names(new_data)
  common <- intersect(old_names, new_names)
  if (is.null(columns)) {
    columns <- setdiff(common, c(key, ignore))
  } else {
    missing_columns <- setdiff(columns, common)
    if (length(missing_columns)) {
      cli::cli_abort("Comparison {.arg columns} missing from one or both releases: {missing_columns}.")
    }
    columns <- setdiff(columns, c(key, ignore))
  }
  if (!length(columns)) cli::cli_abort("No shared non-key columns remain to compare.")

  result <- compare_release_data(
    old_data, new_data, key, columns, tolerance, detail
  )
  result$metadata <- list(
    dataset = dataset,
    old_version = as.character(old_version),
    new_version = as.character(new_version),
    variant = variant,
    key = key,
    compared_columns = columns,
    ignored_columns = intersect(ignore, common),
    columns_added = setdiff(new_names, old_names),
    columns_removed = setdiff(old_names, new_names),
    data_supplied = supplied
  )
  class(result) <- "ucdp_version_comparison"
  result
}

validate_comparison_inputs <- function(dataset, old_version, new_version,
                                       tolerance, old_data, new_data) {
  if (!is.character(dataset) || length(dataset) != 1L || !nzchar(dataset)) {
    cli::cli_abort("{.arg dataset} must be one non-empty character string.")
  }
  for (value in list(old_version = old_version, new_version = new_version)) {
    if (length(value) != 1L || is.na(value)) {
      cli::cli_abort("Version identifiers must each contain one non-missing value.")
    }
  }
  if (!is.numeric(tolerance) || length(tolerance) != 1L ||
      is.na(tolerance) || tolerance < 0) {
    cli::cli_abort("{.arg tolerance} must be one non-negative number.")
  }
  if (xor(is.null(old_data), is.null(new_data))) {
    cli::cli_abort("Supply both {.arg old_data} and {.arg new_data}, or neither.")
  }
  if (!is.null(old_data) &&
      (!is.data.frame(old_data) || !is.data.frame(new_data))) {
    cli::cli_abort("{.arg old_data} and {.arg new_data} must be data frames.")
  }
}

resolve_comparison_key <- function(old, new, key) {
  if (!is.null(key)) return(as.character(key))
  candidates <- list(
    "id", "event_id", c("dyad_id", "year"),
    c("conflict_id", "year"), c("actor_id", "year"), "actor_id",
    c("country_id", "year"), c("gwno", "year"), c("iso3c", "year")
  )
  for (candidate in candidates) {
    if (all(candidate %in% names(old)) && all(candidate %in% names(new)) &&
        key_is_valid(old, candidate) && key_is_valid(new, candidate)) {
      return(candidate)
    }
  }
  cli::cli_abort(c(
    "A unique observation key could not be inferred.",
    "i" = "Supply the key column or columns with {.arg key}."
  ))
}

validate_comparison_key <- function(old, new, key) {
  if (!length(key) || anyNA(key) || any(!nzchar(key))) {
    cli::cli_abort("{.arg key} must contain one or more column names.")
  }
  missing_old <- setdiff(key, names(old))
  missing_new <- setdiff(key, names(new))
  if (length(missing_old) || length(missing_new)) {
    cli::cli_abort(c(
      "Key columns must occur in both releases.",
      "i" = "Missing from old: {missing_old}.",
      "i" = "Missing from new: {missing_new}."
    ))
  }
  if (!key_is_valid(old, key)) {
    cli::cli_abort("{.arg key} is missing or duplicated in the old release.")
  }
  if (!key_is_valid(new, key)) {
    cli::cli_abort("{.arg key} is missing or duplicated in the new release.")
  }
  invisible(key)
}

key_is_valid <- function(data, key) {
  if (anyNA(data[key])) return(FALSE)
  !anyDuplicated(composite_key(data, key))
}

composite_key <- function(data, key) {
  encoded <- lapply(data[key], function(x) {
    x <- as.character(x)
    ifelse(is.na(x), "<NA>", paste0(nchar(x), "#", x))
  })
  do.call(paste, c(encoded, sep = "|"))
}

compare_release_data <- function(old, new, key, columns, tolerance, detail) {
  old_key <- composite_key(old, key)
  new_key <- composite_key(new, key)
  added_index <- which(!new_key %in% old_key)
  removed_index <- which(!old_key %in% new_key)
  common_key <- intersect(old_key, new_key)
  old_match <- match(common_key, old_key)
  new_match <- match(common_key, new_key)

  changes <- lapply(columns, function(column) {
    !values_equal(old[[column]][old_match], new[[column]][new_match], tolerance)
  })
  names(changes) <- columns
  change_matrix <- do.call(cbind, changes)
  if (!is.matrix(change_matrix)) change_matrix <- matrix(change_matrix, ncol = 1L)
  colnames(change_matrix) <- columns
  modified_common <- which(rowSums(change_matrix) > 0L)
  unchanged <- length(common_key) - length(modified_common)

  modified <- old[old_match[modified_common], key, drop = FALSE]
  if (nrow(modified)) {
    modified$changed_columns <- vapply(modified_common, function(i) {
      paste(columns[change_matrix[i, ]], collapse = ", ")
    }, character(1))
  } else {
    modified$changed_columns <- character()
  }

  variable_counts <- colSums(change_matrix)
  variable_summary <- tibble::tibble(
    variable = names(variable_counts),
    n_changed = as.integer(variable_counts)
  )
  variable_summary <- variable_summary[order(variable_summary$n_changed,
                                               decreasing = TRUE), , drop = FALSE]

  cells <- NULL
  if (identical(detail, "cells")) {
    cell_parts <- lapply(columns, function(column) {
      index <- which(changes[[column]])
      if (!length(index)) return(NULL)
      keys <- old[old_match[index], key, drop = FALSE]
      keys$variable <- column
      keys$old_value <- value_text(old[[column]][old_match[index]])
      keys$new_value <- value_text(new[[column]][new_match[index]])
      keys
    })
    cell_parts <- Filter(Negate(is.null), cell_parts)
    cells <- if (length(cell_parts)) {
      tibble::as_tibble(do.call(rbind, cell_parts))
    } else {
      empty_cells(key, old)
    }
  }

  keep_rows <- !identical(detail, "summary")
  list(
    overview = tibble::tibble(
      old_rows = nrow(old), new_rows = nrow(new),
      matched = length(common_key), added = length(added_index),
      removed = length(removed_index), modified = length(modified_common),
      unchanged = unchanged
    ),
    variables = variable_summary,
    added = if (keep_rows) tibble::as_tibble(new[added_index, , drop = FALSE]) else NULL,
    removed = if (keep_rows) tibble::as_tibble(old[removed_index, , drop = FALSE]) else NULL,
    modified = if (keep_rows) tibble::as_tibble(modified) else NULL,
    cell_changes = cells
  )
}

values_equal <- function(x, y, tolerance) {
  both_missing <- is.na(x) & is.na(y)
  one_missing <- xor(is.na(x), is.na(y))
  equal <- rep(FALSE, length(x))
  equal[both_missing] <- TRUE
  comparable <- !both_missing & !one_missing
  if (is.numeric(x) && is.numeric(y)) {
    exactly_equal <- x[comparable] == y[comparable]
    exactly_equal[is.na(exactly_equal)] <- FALSE
    difference <- abs(x[comparable] - y[comparable])
    scale <- pmax(1, abs(x[comparable]), abs(y[comparable]))
    within_tolerance <- difference <= tolerance * scale
    within_tolerance[is.na(within_tolerance)] <- FALSE
    equal[comparable] <- exactly_equal | within_tolerance
  } else {
    equal[comparable] <- as.character(x[comparable]) == as.character(y[comparable])
  }
  equal
}

value_text <- function(x) {
  out <- as.character(x)
  out[is.na(x)] <- NA_character_
  out
}

empty_cells <- function(key, template) {
  out <- template[FALSE, key, drop = FALSE]
  out$variable <- character()
  out$old_value <- character()
  out$new_value <- character()
  tibble::as_tibble(out)
}

#' Print a UCDP version comparison
#'
#' @param x A `ucdp_version_comparison` object.
#' @param ... Additional arguments, currently unused.
#' @return `x`, invisibly.
#' @keywords internal
#' @export
print.ucdp_version_comparison <- function(x, ...) {
  cat("UCDP version comparison\n")
  cat("Dataset: ", x$metadata$dataset, "\n", sep = "")
  cat("Versions: ", x$metadata$old_version, " -> ",
      x$metadata$new_version, "\n", sep = "")
  cat("Key: ", paste(x$metadata$key, collapse = ", "), "\n\n", sep = "")
  print(x$overview)
  invisible(x)
}

#' Summarize a UCDP version comparison
#'
#' @param object A `ucdp_version_comparison` object.
#' @param ... Additional arguments, currently unused.
#' @return A list containing the overview, variable summary, and metadata.
#' @keywords internal
#' @export
summary.ucdp_version_comparison <- function(object, ...) {
  list(
    overview = object$overview,
    variables = object$variables,
    metadata = object$metadata
  )
}
