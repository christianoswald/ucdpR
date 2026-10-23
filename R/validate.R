#' Validate a UCDP dataset
#'
#' `ucdp_validate()` performs transparent structural and range checks commonly
#' relevant to UCDP data. It does not alter the input and does not claim that a
#' flagged value is necessarily a coding error; warnings identify records that
#' merit inspection.
#'
#' @param data A data frame containing UCDP data.
#' @param dataset Optional dataset label used in the returned metadata.
#' @param key Optional columns that should uniquely identify observations. When
#'   omitted, a plausible key is inferred from common UCDP identifiers.
#' @param checks Any of `"keys"`, `"dates"`, `"fatalities"`,
#'   `"coordinates"`, and `"codes"`, or `"all"`.
#' @param strict If `TRUE`, warnings also make the overall result invalid.
#' @return An object of class `ucdp_validation` with `valid`, `summary`,
#'   `issues`, `key`, and `metadata` components.
#' @export
#' @examples
#' example <- data.frame(
#'   id = c(1, 2), year = c(2020, 2021),
#'   low = c(0, 2), best = c(1, 3), high = c(2, 4),
#'   latitude = c(10, 20), longitude = c(30, 40)
#' )
#' ucdp_validate(example)
ucdp_validate <- function(data, dataset = NULL, key = NULL, checks = "all",
                          strict = FALSE) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
    cli::cli_abort("{.arg strict} must be TRUE or FALSE.")
  }
  available <- c("keys", "dates", "fatalities", "coordinates", "codes")
  if (identical(checks, "all")) checks <- available
  if (!is.character(checks) || !length(checks) || anyNA(checks) ||
      any(!checks %in% available)) {
    cli::cli_abort(c(
      "{.arg checks} contains an unsupported value.",
      "i" = "Choose from: {paste(available, collapse = ', ')}, or 'all'."
    ))
  }
  checks <- unique(checks)
  selected_key <- if ("keys" %in% checks) validation_key(data, key) else character()
  results <- lapply(checks, function(check) {
    switch(check,
      keys = validate_keys(data, selected_key),
      dates = validate_dates(data),
      fatalities = validate_fatalities(data),
      coordinates = validate_coordinates(data),
      codes = validate_codes(data)
    )
  })
  names(results) <- checks
  issues <- do.call(rbind, lapply(results, `[[`, "issues"))
  if (is.null(issues)) issues <- empty_validation_issues()
  issues <- tibble::as_tibble(issues)
  summaries <- lapply(names(results), function(name) {
    item <- results[[name]]
    severities <- item$issues$severity
    status <- if (!item$applicable) {
      "skipped"
    } else if ("error" %in% severities) {
      "fail"
    } else if ("warning" %in% severities) {
      "warning"
    } else {
      "pass"
    }
    tibble::tibble(check = name, status = status, n_issues = nrow(item$issues))
  })
  summary <- do.call(rbind, summaries)
  has_error <- any(issues$severity == "error")
  has_warning <- any(issues$severity == "warning")
  result <- list(
    valid = !has_error && (!strict || !has_warning),
    summary = tibble::as_tibble(summary),
    issues = issues,
    key = selected_key,
    metadata = ucdp_metadata(data, dataset = dataset)
  )
  class(result) <- "ucdp_validation"
  result
}

validation_key <- function(data, key) {
  if (!is.null(key)) {
    key <- as.character(key)
    missing <- setdiff(key, names(data))
    if (!length(key) || anyNA(key) || any(!nzchar(key)) || length(missing)) {
      cli::cli_abort(c(
        "{.arg key} must name columns in {.arg data}.",
        "i" = "Missing columns: {missing}."
      ))
    }
    return(key)
  }
  candidates <- list(
    "id", "event_id", c("dyad_id", "year"),
    c("conflict_id", "year"), c("actor_id", "year"), "actor_id",
    c("country_id", "year"), c("gwno", "year"), c("iso3c", "year")
  )
  for (candidate in candidates) {
    if (all(candidate %in% names(data))) return(candidate)
  }
  character()
}

validation_result <- function(issues = empty_validation_issues(), applicable = TRUE) {
  list(issues = issues, applicable = applicable)
}

empty_validation_issues <- function() {
  tibble::tibble(
    check = character(), severity = character(), row = integer(),
    column = character(), value = character(), message = character()
  )
}

validation_issue <- function(check, severity, rows, column, values, message) {
  rows <- as.integer(rows)
  if (!length(rows)) return(empty_validation_issues())
  if (length(values) == 1L) values <- rep(values, length(rows))
  tibble::tibble(
    check = rep(check, length(rows)), severity = rep(severity, length(rows)),
    row = rows, column = rep(paste(column, collapse = ", "), length(rows)),
    value = as.character(values), message = rep(message, length(rows))
  )
}

bind_validation_issues <- function(...) {
  parts <- list(...)
  parts <- parts[vapply(parts, nrow, integer(1)) > 0L]
  if (!length(parts)) return(empty_validation_issues())
  tibble::as_tibble(do.call(rbind, parts))
}

validate_keys <- function(data, key) {
  if (!length(key)) return(validation_result(applicable = FALSE))
  missing <- which(!stats::complete.cases(data[key]))
  complete <- stats::complete.cases(data[key])
  encoded <- rep(NA_character_, nrow(data))
  if (any(complete)) encoded[complete] <- composite_key(data[complete, , drop = FALSE], key)
  duplicated_rows <- which(complete & (duplicated(encoded) | duplicated(encoded, fromLast = TRUE)))
  validation_result(bind_validation_issues(
    validation_issue("keys", "error", missing, key, NA_character_,
                     "Observation key contains a missing value."),
    validation_issue("keys", "error", duplicated_rows, key,
                     encoded[duplicated_rows],
                     "Observation key is duplicated.")
  ))
}

validate_dates <- function(data) {
  date_names <- intersect(c("date_start", "date_end", "date"), names(data))
  if (!length(date_names)) return(validation_result(applicable = FALSE))
  issues <- lapply(date_names, function(name) {
    raw <- data[[name]]
    parsed <- parse_ucdp_date(raw)
    nonempty <- !is.na(raw) & nzchar(trimws(as.character(raw)))
    bad <- which(nonempty & is.na(parsed))
    validation_issue("dates", "error", bad, name, raw[bad],
                     "Date cannot be parsed as YYYY-MM-DD.")
  })
  if (all(c("date_start", "date_end") %in% date_names)) {
    start <- parse_ucdp_date(data$date_start)
    end <- parse_ucdp_date(data$date_end)
    rows <- which(!is.na(start) & !is.na(end) & start > end)
    issues[[length(issues) + 1L]] <- validation_issue(
      "dates", "error", rows, c("date_start", "date_end"),
      paste(data$date_start[rows], data$date_end[rows], sep = " > "),
      "Start date occurs after end date."
    )
  }
  year_name <- first_name(data, c("year", "Year"))
  reference_date <- first_name(data, c("date_start", "date"))
  if (!is.na(year_name) && !is.na(reference_date)) {
    date <- parse_ucdp_date(data[[reference_date]])
    year <- suppressWarnings(as.integer(as.character(data[[year_name]])))
    rows <- which(!is.na(date) & !is.na(year) &
                    as.integer(format(date, "%Y")) != year)
    issues[[length(issues) + 1L]] <- validation_issue(
      "dates", "warning", rows, c(year_name, reference_date),
      paste(year[rows], data[[reference_date]][rows], sep = " / "),
      "Year differs from the reference date year."
    )
  }
  validation_result(do.call(bind_validation_issues, issues))
}

validate_fatalities <- function(data) {
  names_lower <- tolower(names(data))
  candidate <- grepl("(^|_)(best|low|high)$|death|fatal", names_lower)
  fatality_names <- names(data)[candidate]
  if (!length(fatality_names)) return(validation_result(applicable = FALSE))
  issues <- lapply(fatality_names, function(name) {
    raw <- data[[name]]
    value <- suppressWarnings(as.numeric(as.character(raw)))
    nonempty <- !is.na(raw) & nzchar(trimws(as.character(raw)))
    invalid <- which(nonempty & is.na(value))
    negative <- which(!is.na(value) & value < 0)
    bind_validation_issues(
      validation_issue("fatalities", "error", invalid, name, raw[invalid],
                       "Fatality estimate is not numeric."),
      validation_issue("fatalities", "error", negative, name, raw[negative],
                       "Fatality estimate is negative.")
    )
  })
  triples <- list(c("low", "best", "high"), c("bd_low", "bd_best", "bd_high"),
                  c("deaths_low", "deaths_best", "deaths_high"))
  for (triple in triples) {
    if (!all(triple %in% names(data))) next
    low <- suppressWarnings(as.numeric(data[[triple[[1L]]]]))
    best <- suppressWarnings(as.numeric(data[[triple[[2L]]]]))
    high <- suppressWarnings(as.numeric(data[[triple[[3L]]]]))
    rows <- which(!is.na(low) & !is.na(best) & !is.na(high) &
                    (low > best | best > high))
    issues[[length(issues) + 1L]] <- validation_issue(
      "fatalities", "error", rows, triple,
      paste(low[rows], best[rows], high[rows], sep = " / "),
      "Fatality bounds do not satisfy low <= best <= high."
    )
  }
  validation_result(do.call(bind_validation_issues, issues))
}

validate_coordinates <- function(data) {
  lat_name <- first_name(data, c("latitude", "lat"))
  lon_name <- first_name(data, c("longitude", "lon", "long"))
  if (is.na(lat_name) && is.na(lon_name)) return(validation_result(applicable = FALSE))
  lat_issue <- empty_validation_issues()
  lon_issue <- empty_validation_issues()
  if (!is.na(lat_name)) {
    raw <- data[[lat_name]]
    lat <- suppressWarnings(as.numeric(as.character(raw)))
    nonempty <- !is.na(raw) & nzchar(trimws(as.character(raw)))
    invalid <- which(nonempty & is.na(lat))
    rows <- which(!is.na(lat) & (!is.finite(lat) | lat < -90 | lat > 90))
    lat_issue <- bind_validation_issues(
      validation_issue("coordinates", "error", invalid, lat_name, raw[invalid],
                       "Latitude is not numeric."),
      validation_issue("coordinates", "error", rows, lat_name, raw[rows],
                       "Latitude is outside -90 to 90.")
    )
  }
  if (!is.na(lon_name)) {
    raw <- data[[lon_name]]
    lon <- suppressWarnings(as.numeric(as.character(raw)))
    nonempty <- !is.na(raw) & nzchar(trimws(as.character(raw)))
    invalid <- which(nonempty & is.na(lon))
    rows <- which(!is.na(lon) & (!is.finite(lon) | lon < -180 | lon > 180))
    lon_issue <- bind_validation_issues(
      validation_issue("coordinates", "error", invalid, lon_name, raw[invalid],
                       "Longitude is not numeric."),
      validation_issue("coordinates", "error", rows, lon_name, raw[rows],
                       "Longitude is outside -180 to 180.")
    )
  }
  validation_result(bind_validation_issues(lat_issue, lon_issue))
}

validate_codes <- function(data) {
  definitions <- list(type_of_violence = 1:3, type_of_conflict = 1:4)
  definitions <- definitions[names(definitions) %in% names(data)]
  if (!length(definitions)) return(validation_result(applicable = FALSE))
  issues <- lapply(names(definitions), function(name) {
    value <- suppressWarnings(as.integer(as.character(data[[name]])))
    raw <- data[[name]]
    rows <- which(!is.na(raw) & (is.na(value) | !value %in% definitions[[name]]))
    validation_issue(
      "codes", "warning", rows, name, raw[rows],
      paste0("Value is outside the documented range for ", name, ".")
    )
  })
  validation_result(do.call(bind_validation_issues, issues))
}

#' Print a UCDP validation result
#'
#' @param x A `ucdp_validation` object.
#' @param ... Additional arguments, currently unused.
#' @return `x`, invisibly.
#' @keywords internal
#' @export
print.ucdp_validation <- function(x, ...) {
  cat("UCDP data validation\n")
  cat("Result: ", if (x$valid) "valid" else "issues detected", "\n", sep = "")
  if (length(x$key)) cat("Key: ", paste(x$key, collapse = ", "), "\n", sep = "")
  cat("\n")
  print(x$summary)
  invisible(x)
}

#' Summarize a UCDP validation result
#'
#' @param object A `ucdp_validation` object.
#' @param ... Additional arguments, currently unused.
#' @return The check summary.
#' @keywords internal
#' @export
summary.ucdp_validation <- function(object, ...) object$summary
