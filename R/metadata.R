#' Summarize UCDP provenance and data coverage
#'
#' `ucdp_metadata()` returns a standardized, one-row summary for an imported
#' UCDP object, a path returned by [ucdp_download()], or a dataset available in
#' the official catalog. Objects imported by [ucdp_get()] retain the richest
#' provenance information.
#'
#' @param x A data object, downloaded path, or dataset name or alias.
#' @param dataset Optional dataset label used for an object without provenance.
#' @param version Optional exact release when `x` is a dataset name.
#' @param variant Optional dataset variant when `x` is a dataset name.
#' @param format File format used to resolve a catalog entry.
#' @param catalog Optional pre-fetched catalog.
#' @param quiet Suppress catalog messages?
#' @return A one-row tibble containing provenance, dimensions, and available
#'   temporal and geographic coverage.
#' @export
#' @examples
#' example <- data.frame(year = 2020:2022, latitude = c(1, 2, 3),
#'                       longitude = c(4, 5, 6))
#' ucdp_metadata(example, dataset = "Example UCDP data")
#' \dontrun{
#' ged <- ucdp_get("ged", version = "25.1")
#' ucdp_metadata(ged)
#' ucdp_metadata("ged", version = "25.1")
#' }
ucdp_metadata <- function(x, dataset = NULL, version = NULL, variant = NULL,
                          format = "csv", catalog = NULL, quiet = FALSE) {
  is_path <- is.character(x) && length(x) == 1L && !is.na(x) && file.exists(x)
  is_query <- is.character(x) && length(x) == 1L && !is.na(x) && !is_path &&
    is.null(dataset)

  if (is_query) {
    record <- metadata_catalog_record(
      x, version = version, variant = variant, format = format,
      catalog = catalog, quiet = quiet
    )
    return(metadata_tibble(record = record, dataset = NULL, object = NULL,
                           path = NULL, source = NULL))
  }

  if (is.character(x) && length(x) != 1L) {
    cli::cli_abort("{.arg x} must be one path, one dataset name, or a data object.")
  }
  source <- attr(x, "ucdp_source", exact = TRUE)
  if (is_path && is.null(source)) {
    source <- attributes(x)[c(
      "ucdp_record", "ucdp_version", "md5", "retrieved_at", "ucdpR_version"
    )]
  }
  record <- if (is.list(source)) source$ucdp_record else NULL
  object <- if (is.data.frame(x)) x else NULL
  metadata_tibble(record, dataset, object, if (is_path) x else NULL, source)
}

metadata_catalog_record <- function(dataset, version, variant, format,
                                    catalog, quiet) {
  format <- match.arg(tolower(format), c(
    "csv", "xlsx", "dta", "rdata", "rds", "sql", "shapefile",
    "geojson", "kml", "shx", "zip", "any"
  ))
  if (is.null(catalog)) {
    catalog <- ucdp_catalog(
      include_historical = !is.null(version), quiet = quiet
    )
  }
  choices <- ucdp_search(resolve_alias(dataset), catalog)
  if (format != "any") choices <- choices[choices$format == format, , drop = FALSE]
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
  select_one(choices, dataset, format, variant, version)
}

metadata_tibble <- function(record, dataset, object, path, source) {
  field <- function(name, default = NA_character_) {
    if (is.null(record) || !name %in% names(record) || !length(record[[name]])) {
      return(default)
    }
    value <- record[[name]][[1L]]
    if (is.factor(value)) value <- as.character(value)
    value
  }
  source_field <- function(name) {
    if (!is.list(source) || is.null(source[[name]]) || !length(source[[name]])) {
      return(NA_character_)
    }
    as.character(source[[name]][[1L]])
  }
  coverage <- data_coverage(object)
  file_name <- field("file_name")
  if (!is.null(path)) file_name <- basename(path)
  file_format <- field("format")
  if (!is.null(path) && is.na(file_format)) {
    file_format <- tolower(tools::file_ext(path))
  }
  tibble::tibble(
    dataset = if (!is.null(dataset)) as.character(dataset)[1L] else field("dataset"),
    version = if (!is.null(source)) source_field("ucdp_version") else field("version"),
    variant = field("variant"),
    format = file_format,
    file_name = file_name,
    source_url = field("url"),
    catalog_source = field("source"),
    retrieved_at = source_field("retrieved_at"),
    md5 = source_field("md5"),
    ucdpR_version = source_field("ucdpR_version"),
    n_rows = if (is.null(object)) NA_integer_ else nrow(object),
    n_columns = if (is.null(object)) NA_integer_ else ncol(object),
    year_min = coverage$year_min,
    year_max = coverage$year_max,
    date_min = coverage$date_min,
    date_max = coverage$date_max,
    latitude_min = coverage$latitude_min,
    latitude_max = coverage$latitude_max,
    longitude_min = coverage$longitude_min,
    longitude_max = coverage$longitude_max
  )
}

data_coverage <- function(data) {
  empty <- list(
    year_min = NA_integer_, year_max = NA_integer_,
    date_min = NA_character_, date_max = NA_character_,
    latitude_min = NA_real_, latitude_max = NA_real_,
    longitude_min = NA_real_, longitude_max = NA_real_
  )
  if (is.null(data) || !nrow(data)) return(empty)
  year_name <- first_name(data, c("year", "Year"))
  if (!is.na(year_name)) {
    years <- suppressWarnings(as.integer(as.character(data[[year_name]])))
    years <- years[is.finite(years)]
    if (length(years)) {
      empty$year_min <- min(years)
      empty$year_max <- max(years)
    }
  }
  date_names <- intersect(c("date_start", "date_end", "date"), names(data))
  if (length(date_names)) {
    dates <- unlist(lapply(data[date_names], parse_ucdp_date), use.names = FALSE)
    dates <- as.Date(dates, origin = "1970-01-01")
    dates <- dates[!is.na(dates)]
    if (length(dates)) {
      empty$date_min <- format(min(dates), "%Y-%m-%d")
      empty$date_max <- format(max(dates), "%Y-%m-%d")
    }
  }
  lat <- first_name(data, c("latitude", "lat"))
  lon <- first_name(data, c("longitude", "lon", "long"))
  if (!is.na(lat)) {
    values <- suppressWarnings(as.numeric(data[[lat]]))
    values <- values[is.finite(values)]
    if (length(values)) {
      empty$latitude_min <- min(values)
      empty$latitude_max <- max(values)
    }
  }
  if (!is.na(lon)) {
    values <- suppressWarnings(as.numeric(data[[lon]]))
    values <- values[is.finite(values)]
    if (length(values)) {
      empty$longitude_min <- min(values)
      empty$longitude_max <- max(values)
    }
  }
  empty
}

first_name <- function(data, candidates) {
  hit <- candidates[candidates %in% names(data)]
  if (length(hit)) hit[[1L]] else NA_character_
}

parse_ucdp_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  suppressWarnings(as.Date(as.character(x)))
}
