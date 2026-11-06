#' Convert georeferenced UCDP data to an sf object
#'
#' `ucdp_as_sf()` recognizes common UCDP coordinate columns and converts them
#' to point geometry. The original `ucdp_source` provenance attribute is
#' retained, making the result suitable for later spatial joins, including
#' workflows built around the released `priogrid` package or a future
#' `priogridR` package.
#'
#' @param data A data frame containing coordinates, or an existing `sf` object.
#' @param longitude,latitude Coordinate column names. When omitted, common UCDP
#'   names are detected automatically.
#' @param crs Coordinate reference system passed to [sf::st_as_sf()]. UCDP GED
#'   coordinates use EPSG 4326.
#' @param remove Remove the source coordinate columns?
#' @param missing How to handle missing coordinates: retain them as empty
#'   geometries, drop their rows, or raise an error.
#' @return An `sf` object with point geometry.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:3, longitude = c(10, 20, NA), latitude = c(50, 60, NA)
#' )
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   events_sf <- ucdp_as_sf(events, missing = "drop")
#'   sf::st_crs(events_sf)
#' }
ucdp_as_sf <- function(data, longitude = NULL, latitude = NULL, crs = 4326,
                       remove = FALSE,
                       missing = c("keep", "drop", "error")) {
  require_optional("sf", "convert UCDP data to spatial features")
  missing <- match.arg(missing)
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!is.logical(remove) || length(remove) != 1L || is.na(remove)) {
    cli::cli_abort("{.arg remove} must be TRUE or FALSE.")
  }
  provenance <- attr(data, "ucdp_source", exact = TRUE)

  if (inherits(data, "sf")) {
    result <- if (is.na(sf::st_crs(data))) {
      sf::st_set_crs(data, crs)
    } else if (sf::st_crs(data) != sf::st_crs(crs)) {
      sf::st_transform(data, crs)
    } else {
      data
    }
    if (!is.null(provenance)) attr(result, "ucdp_source") <- provenance
    return(result)
  }

  longitude <- resolve_coordinate(data, longitude, c("longitude", "lon", "long"),
                                  "longitude")
  latitude <- resolve_coordinate(data, latitude, c("latitude", "lat"), "latitude")
  lon <- numeric_coordinate(data[[longitude]], longitude)
  lat <- numeric_coordinate(data[[latitude]], latitude)

  target_crs <- sf::st_crs(crs)
  if (!is.na(target_crs$epsg) && target_crs$epsg == 4326L) {
    bad_lon <- which(!is.na(lon) & (lon < -180 | lon > 180))
    bad_lat <- which(!is.na(lat) & (lat < -90 | lat > 90))
    if (length(bad_lon) || length(bad_lat)) {
      cli::cli_abort(c(
        "Coordinates are outside the valid range for EPSG 4326.",
        "i" = "Invalid longitude rows: {bad_lon}.",
        "i" = "Invalid latitude rows: {bad_lat}."
      ))
    }
  }
  incomplete <- is.na(lon) | is.na(lat)
  if (missing == "error" && any(incomplete)) {
    cli::cli_abort("Missing coordinates occur in rows: {which(incomplete)}.")
  }
  if (missing == "drop") {
    data <- data[!incomplete, , drop = FALSE]
    lon <- lon[!incomplete]
    lat <- lat[!incomplete]
  }
  data[[longitude]] <- lon
  data[[latitude]] <- lat
  result <- sf::st_as_sf(
    data, coords = c(longitude, latitude), crs = crs,
    remove = remove, na.fail = FALSE
  )
  if (!is.null(provenance)) attr(result, "ucdp_source") <- provenance
  attr(result, "ucdp_coordinates") <- c(longitude = longitude, latitude = latitude)
  result
}

resolve_coordinate <- function(data, supplied, candidates, argument) {
  if (!is.null(supplied)) {
    if (!is.character(supplied) || length(supplied) != 1L ||
        is.na(supplied) || !nzchar(supplied) || !supplied %in% names(data)) {
      cli::cli_abort("{.arg {argument}} must name one column in {.arg data}.")
    }
    return(supplied)
  }
  found <- candidates[candidates %in% names(data)]
  if (!length(found)) {
    cli::cli_abort(c(
      "Could not identify the {.field {argument}} column.",
      "i" = "Supply its name explicitly with {.arg {argument}}."
    ))
  }
  found[[1L]]
}

numeric_coordinate <- function(x, name) {
  value <- suppressWarnings(as.numeric(as.character(x)))
  nonempty <- !is.na(x) & nzchar(trimws(as.character(x)))
  invalid <- which(nonempty & is.na(value))
  if (length(invalid)) {
    cli::cli_abort("Column {.field {name}} contains non-numeric coordinates in rows: {invalid}.")
  }
  value
}

#' Summarize spatial and temporal precision in UCDP event data
#'
#' @param data A data frame containing `where_prec` and/or `date_prec`.
#' @param by Optional grouping columns, such as `"year"` or
#'   `c("country", "year")`.
#' @param include_missing Include missing precision values in the summary?
#' @return A tibble with grouping variables, precision dimension, code, label,
#'   count, and within-group share.
#' @export
#' @examples
#' events <- data.frame(
#'   year = c(2020, 2020, 2021),
#'   where_prec = c(1, 2, 2), date_prec = c(1, 1, 3)
#' )
#' ucdp_precision(events)
#' ucdp_precision(events, by = "year")
ucdp_precision <- function(data, by = NULL, include_missing = TRUE) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!is.logical(include_missing) || length(include_missing) != 1L ||
      is.na(include_missing)) {
    cli::cli_abort("{.arg include_missing} must be TRUE or FALSE.")
  }
  by <- validate_group_columns(data, by)
  variables <- intersect(c("where_prec", "date_prec"), names(data))
  if (!length(variables)) {
    cli::cli_abort("{.arg data} contains neither {.field where_prec} nor {.field date_prec}.")
  }
  parts <- lapply(variables, function(variable) {
    precision_summary(data, variable, by, include_missing)
  })
  out <- tibble::as_tibble(do.call(rbind, parts))
  attr(out, "ucdp_source") <- attr(data, "ucdp_source", exact = TRUE)
  out
}

validate_group_columns <- function(data, by) {
  if (is.null(by)) return(character())
  if (!is.character(by) || anyNA(by) || any(!nzchar(by))) {
    cli::cli_abort("{.arg by} must contain column names.")
  }
  missing <- setdiff(by, names(data))
  if (length(missing)) cli::cli_abort("Grouping columns not found: {missing}.")
  unique(by)
}

precision_summary <- function(data, variable, by, include_missing) {
  group_key <- if (length(by)) composite_key(data, by) else rep("all", nrow(data))
  keys <- unique(group_key)
  parts <- lapply(keys, function(key) {
    rows <- which(group_key == key)
    raw <- data[[variable]][rows]
    code <- suppressWarnings(as.integer(as.character(raw)))
    invalid <- which(!is.na(raw) & is.na(code))
    if (length(invalid)) {
      cli::cli_abort("{.field {variable}} contains non-integer values in rows: {rows[invalid]}.")
    }
    values <- sort(unique(code[!is.na(code)]))
    if (include_missing && any(is.na(code))) values <- c(values, NA_integer_)
    if (!length(values)) return(NULL)
    counts <- vapply(values, function(value) {
      if (is.na(value)) sum(is.na(code)) else sum(code == value, na.rm = TRUE)
    }, integer(1))
    groups <- if (length(by)) data[rep(rows[[1L]], length(values)), by, drop = FALSE] else NULL
    result <- data.frame(
      dimension = rep(if (variable == "where_prec") "spatial" else "temporal",
                      length(values)),
      variable = rep(variable, length(values)),
      code = values,
      label = precision_label(variable, values),
      n = counts,
      share = counts / length(rows),
      stringsAsFactors = FALSE
    )
    if (length(by)) result <- cbind(groups, result)
    result
  })
  parts <- Filter(Negate(is.null), parts)
  if (!length(parts)) return(empty_precision_summary(data, by))
  do.call(rbind, parts)
}

precision_label <- function(variable, code) {
  labels <- if (variable == "where_prec") {
    c(
      "1" = "Exact location",
      "2" = "Within approximately 25 km",
      "3" = "Second-order administrative division",
      "4" = "First-order administrative division",
      "5" = "Linear feature or imprecise area",
      "6" = "Country only",
      "7" = "International waters or airspace"
    )
  } else {
    c(
      "1" = "Exact date",
      "2" = "Two-to-six-day range",
      "3" = "Week known",
      "4" = "Eight-to-thirty-day range or month known",
      "5" = "More than one month but less than one year"
    )
  }
  out <- unname(labels[as.character(code)])
  out[is.na(code)] <- "Missing"
  out[is.na(out)] <- "Unknown code"
  out
}

empty_precision_summary <- function(data, by) {
  groups <- data[FALSE, by, drop = FALSE]
  tibble::as_tibble(cbind(
    groups,
    data.frame(
      dimension = character(), variable = character(), code = integer(),
      label = character(), n = integer(), share = numeric()
    )
  ))
}

#' Filter UCDP events by spatial and temporal precision
#'
#' @param data A data frame containing UCDP precision variables.
#' @param where_prec Spatial precision codes to retain. `NULL` applies no
#'   spatial filter.
#' @param date_prec Temporal precision codes to retain. `NULL` applies no
#'   temporal filter.
#' @param missing Whether missing values in an actively filtered precision
#'   variable should be dropped, retained, or treated as an error.
#' @return `data` restricted to the requested precision, with provenance and
#'   spatial class retained.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:4, where_prec = c(1, 2, 6, NA), date_prec = c(1, 3, 5, 1)
#' )
#' ucdp_filter_precision(events, where_prec = 1:2, date_prec = 1:3)
#' ucdp_filter_precision(events, where_prec = 1:2, missing = "keep")
ucdp_filter_precision <- function(data, where_prec = NULL, date_prec = NULL,
                                  missing = c("drop", "keep", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  missing <- match.arg(missing)
  requested <- list(where_prec = where_prec, date_prec = date_prec)
  active <- names(requested)[!vapply(requested, is.null, logical(1))]
  if (!length(active)) return(data)
  absent <- setdiff(active, names(data))
  if (length(absent)) cli::cli_abort("Precision columns not found: {absent}.")

  keep <- rep(TRUE, nrow(data))
  for (name in active) {
    accepted <- requested[[name]]
    if (!is.numeric(accepted) || !length(accepted) || anyNA(accepted)) {
      cli::cli_abort("{.arg {name}} must contain one or more non-missing numeric codes.")
    }
    value <- suppressWarnings(as.integer(as.character(data[[name]])))
    missing_rows <- is.na(value)
    if (missing == "error" && any(missing_rows)) {
      cli::cli_abort("Missing values occur in {.field {name}} at rows: {which(missing_rows)}.")
    }
    selected <- value %in% as.integer(accepted)
    if (missing == "keep") selected[missing_rows] <- TRUE
    keep <- keep & selected
  }
  result <- data[keep, , drop = FALSE]
  provenance <- attr(data, "ucdp_source", exact = TRUE)
  if (!is.null(provenance)) attr(result, "ucdp_source") <- provenance
  result
}

require_optional <- function(package, purpose) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cli::cli_abort("Install the {.pkg {package}} package to {purpose}.")
  }
}
