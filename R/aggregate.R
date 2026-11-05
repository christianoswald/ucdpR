#' Summarize UCDP fatality estimates
#'
#' `ucdp_fatalities()` aggregates the low, best, and high fatality estimates
#' while retaining information about incomplete observations. It recognizes
#' common UCDP triplets such as `low`/`best`/`high` and
#' `bd_low`/`bd_best`/`bd_high`.
#'
#' @param data A data frame containing fatality estimates.
#' @param by Optional grouping columns.
#' @param low,best,high Optional column names for the three estimates. Supply
#'   all three or none. When omitted, common UCDP names are detected.
#' @param na_rm If `TRUE`, sum the available estimates, but return `NA` when a
#'   group contains no observed value for an estimate. If `FALSE`, any missing
#'   value makes the corresponding group total `NA`.
#' @param missing How to handle missing grouping values: drop their rows or
#'   raise an error.
#' @return A tibble containing grouping variables, observation counts,
#'   completeness counts, and aggregated low, best, and high estimates.
#' @export
#' @examples
#' events <- data.frame(
#'   country = c("A", "A", "B"),
#'   low = c(1, 2, NA), best = c(2, 3, 4), high = c(3, 5, 6)
#' )
#' ucdp_fatalities(events)
#' ucdp_fatalities(events, by = "country")
ucdp_fatalities <- function(data, by = NULL, low = NULL, best = NULL,
                            high = NULL, na_rm = TRUE,
                            missing = c("drop", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  validate_flag(na_rm, "na_rm")
  missing <- match.arg(missing)
  source <- attr(data, "ucdp_source", exact = TRUE)
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  by <- aggregation_columns(data, by, "by")
  columns <- resolve_fatality_columns(data, low, best, high, required = TRUE)
  values <- fatality_values(data, columns)

  keep <- complete_group_rows(data, by)
  dropped <- sum(!keep)
  if (dropped && missing == "error") {
    cli::cli_abort("Missing grouping values occur in {dropped} row(s).")
  }
  data <- data[keep, , drop = FALSE]
  values <- lapply(values, `[`, keep)
  if (!nrow(data)) cli::cli_abort("No rows remain after removing missing grouping values.")

  out <- summarize_fatality_groups(data, by, values, na_rm)
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_fatality_columns") <- columns
  attr(out, "ucdp_rows_dropped") <- dropped
  out
}

#' Aggregate UCDP event data to common analytical units
#'
#' `ucdp_aggregate()` constructs event counts and, when available, aggregated
#' fatality bounds for country, PRIO-GRID, conflict, or dyad panels. Entity and
#' time columns are detected from common UCDP names or can be supplied
#' explicitly.
#'
#' @param data A data frame containing event-level or other disaggregated UCDP
#'   observations.
#' @param unit One of `"country-year"`, `"country-month"`,
#'   `"grid-year"`, `"grid-month"`, `"conflict-year"`,
#'   `"conflict-month"`, `"dyad-year"`, or `"dyad-month"`. Underscores are
#'   accepted in place of hyphens.
#' @param id Optional entity column or columns. When omitted, common names are
#'   detected for the selected unit.
#' @param date Optional date column used to derive year and month. Existing
#'   `year` and `month` columns are preferred when both are available.
#' @param by Additional grouping columns retained in the output.
#' @param include_fatalities Include aggregated fatality estimates when a
#'   recognized triplet is present?
#' @param low,best,high Optional fatality columns passed to the same detection
#'   logic as [ucdp_fatalities()].
#' @param na_rm Missing-value behavior for fatality sums; see
#'   [ucdp_fatalities()].
#' @param missing How to handle missing entity, time, or additional grouping
#'   values: drop their rows or raise an error.
#' @return A tibble with one row per unit-period combination, `n_events`, and,
#'   when available, fatality totals and completeness counts. Provenance and an
#'   aggregation specification are attached as attributes.
#' @export
#' @examples
#' events <- data.frame(
#'   country_id = c(1, 1, 1, 2), country = c("A", "A", "A", "B"),
#'   year = c(2020, 2020, 2021, 2020),
#'   low = c(0, 1, 2, 1), best = c(1, 2, 3, 2), high = c(2, 3, 4, 3)
#' )
#' ucdp_aggregate(events, unit = "country-year")
ucdp_aggregate <- function(data, unit, id = NULL, date = NULL, by = NULL,
                           include_fatalities = TRUE, low = NULL, best = NULL,
                           high = NULL, na_rm = TRUE,
                           missing = c("drop", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  validate_flag(include_fatalities, "include_fatalities")
  validate_flag(na_rm, "na_rm")
  missing <- match.arg(missing)

  spec <- resolve_aggregation_spec(data, unit, id, date, by)
  working <- as.data.frame(data, stringsAsFactors = FALSE)
  working$year <- spec$year
  if (identical(spec$period, "month")) working$month <- spec$month
  groups <- unique(c(spec$entity, spec$by, "year",
                     if (identical(spec$period, "month")) "month"))

  keep <- complete_group_rows(working, groups)
  dropped <- sum(!keep)
  if (dropped && missing == "error") {
    cli::cli_abort("Missing entity, time, or grouping values occur in {dropped} row(s).")
  }
  working <- working[keep, , drop = FALSE]
  if (!nrow(working)) cli::cli_abort("No rows remain after removing incomplete aggregation keys.")

  fatality_columns <- NULL
  fatality_data <- NULL
  if (include_fatalities) {
    fatality_columns <- resolve_fatality_columns(
      working, low, best, high, required = !all(vapply(
        list(low, best, high), is.null, logical(1)
      ))
    )
    if (!is.null(fatality_columns)) {
      fatality_data <- fatality_values(working, fatality_columns)
    }
  }

  out <- summarize_aggregation_groups(
    working, groups, fatality_data, na_rm
  )
  source <- attr(data, "ucdp_source", exact = TRUE)
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_aggregation") <- list(
    unit = spec$unit,
    entity = spec$entity,
    by = spec$by,
    time = c("year", if (identical(spec$period, "month")) "month"),
    period = spec$period,
    fatality_columns = fatality_columns,
    rows_dropped = dropped
  )
  out
}

#' Construct complete UCDP analytical panels
#'
#' `ucdp_panel()` completes the entity-period combinations in an aggregated
#' data set. It can also aggregate raw data first when `unit` is supplied.
#' Inserted rows are always identified by `.ucdp_observed` and `.ucdp_fill`, so
#' zero-filled combinations are never indistinguishable from source groups.
#'
#' @param data Raw UCDP observations or output from [ucdp_aggregate()].
#' @param unit Aggregation unit used for raw data. It may be omitted when
#'   `data` retains the `ucdp_aggregation` attribute.
#' @param id,date,by,include_fatalities,low,best,high,na_rm Passed to
#'   [ucdp_aggregate()] when raw data are supplied.
#' @param start,end Panel boundaries. Use four-digit years for yearly panels
#'   and `"YYYY-MM"` strings or dates for monthly panels. Defaults to the
#'   observed range.
#' @param universe Optional entity universe. Supply a vector for a one-column
#'   entity key or a data frame containing all entity and `by` columns. The
#'   default uses combinations observed at least once in `data`.
#' @param fill Should inserted combinations contain explicit zeroes in numeric
#'   aggregate columns or missing values?
#' @param missing Passed to [ucdp_aggregate()] for raw data.
#' @return A complete panel tibble. `.ucdp_observed` is `TRUE` only for groups
#'   present in the aggregated input; `.ucdp_fill` is `"observed"`,
#'   `"zero_filled"`, or `"missing"`.
#' @export
#' @examples
#' events <- data.frame(
#'   country_id = c(1, 1, 2), year = c(2020, 2022, 2021),
#'   low = c(0, 1, 2), best = c(1, 2, 3), high = c(2, 3, 4)
#' )
#' panel <- ucdp_panel(
#'   events, unit = "country-year", start = 2020, end = 2022
#' )
#' panel[c("country_id", "year", "n_events", ".ucdp_fill")]
ucdp_panel <- function(data, unit = NULL, id = NULL, date = NULL, by = NULL,
                       start = NULL, end = NULL, universe = NULL,
                       fill = c("zero", "missing"),
                       include_fatalities = TRUE, low = NULL, best = NULL,
                       high = NULL, na_rm = TRUE,
                       missing = c("drop", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  fill <- match.arg(fill)
  missing <- match.arg(missing)
  aggregation <- attr(data, "ucdp_aggregation", exact = TRUE)

  if (is.null(aggregation)) {
    if ("n_events" %in% names(data)) {
      cli::cli_abort(c(
        "Aggregated-looking data lack an {.field ucdp_aggregation} specification.",
        "i" = "Pass the in-memory output of {.fn ucdp_aggregate}, or supply raw observations."
      ))
    }
    if (is.null(unit)) {
      cli::cli_abort(c(
        "{.arg unit} is required for raw data.",
        "i" = "Alternatively, pass output from {.fn ucdp_aggregate}."
      ))
    }
    aggregated <- ucdp_aggregate(
      data, unit = unit, id = id, date = date, by = by,
      include_fatalities = include_fatalities,
      low = low, best = best, high = high, na_rm = na_rm,
      missing = missing
    )
    aggregation <- attr(aggregated, "ucdp_aggregation", exact = TRUE)
  } else {
    aggregated <- tibble::as_tibble(data)
    if (!is.null(unit) && normalize_aggregation_unit(unit) != aggregation$unit) {
      cli::cli_abort("{.arg unit} does not match the stored aggregation specification.")
    }
  }

  entity <- unique(c(aggregation$entity, aggregation$by))
  time <- aggregation$time
  keys <- c(entity, time)
  missing_columns <- setdiff(keys, names(aggregated))
  if (length(missing_columns)) {
    cli::cli_abort("Panel key columns are missing: {missing_columns}.")
  }
  if (anyNA(aggregated[keys])) {
    cli::cli_abort("Aggregated panel keys must not contain missing values.")
  }
  if (anyDuplicated(composite_key(aggregated, keys))) {
    cli::cli_abort("Aggregated panel keys must be unique.")
  }

  entities <- panel_universe(aggregated, entity, universe)
  periods <- panel_periods(aggregated, aggregation$period, start, end)
  skeleton <- cross_panel(entities, periods)
  source_key <- composite_key(aggregated, keys)
  target_key <- composite_key(skeleton, keys)
  matched <- match(target_key, source_key)
  observed <- !is.na(matched)

  measures <- setdiff(names(aggregated), keys)
  out <- skeleton
  for (name in measures) {
    values <- aggregated[[name]][matched]
    zero_measure <- grepl(
      "^(n_events|n_fatality_complete|n_fatality_missing|fatalities_(low|best|high))$",
      name
    )
    if (fill == "zero" && zero_measure && is.numeric(values)) {
      values[!observed] <- if (is.integer(values)) 0L else 0
    }
    out[[name]] <- values
  }
  out$.ucdp_observed <- observed
  out$.ucdp_fill <- ifelse(
    observed, "observed", if (fill == "zero") "zero_filled" else "missing"
  )
  out <- tibble::as_tibble(out)

  source <- attr(data, "ucdp_source", exact = TRUE)
  if (is.null(source)) source <- attr(aggregated, "ucdp_source", exact = TRUE)
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_aggregation") <- aggregation
  attr(out, "ucdp_panel") <- list(
    fill = fill, start = start, end = end,
    universe_rows = nrow(entities)
  )
  out
}

validate_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {name}} must be TRUE or FALSE.")
  }
  invisible(x)
}

aggregation_columns <- function(data, columns, argument) {
  if (is.null(columns)) return(character())
  if (!is.character(columns) || !length(columns) || anyNA(columns) ||
      any(!nzchar(columns))) {
    cli::cli_abort("{.arg {argument}} must contain column names.")
  }
  absent <- setdiff(columns, names(data))
  if (length(absent)) cli::cli_abort("Columns not found in {.arg data}: {absent}.")
  unique(columns)
}

resolve_fatality_columns <- function(data, low, best, high, required = FALSE) {
  supplied <- !vapply(list(low, best, high), is.null, logical(1))
  if (any(supplied) && !all(supplied)) {
    cli::cli_abort("Supply all of {.arg low}, {.arg best}, and {.arg high}, or none.")
  }
  if (all(supplied)) {
    columns <- c(low = low, best = best, high = high)
    if (any(lengths(columns) != 1L) || anyNA(columns) || any(!nzchar(columns))) {
      cli::cli_abort("Fatality column arguments must each name one column.")
    }
    absent <- setdiff(unname(columns), names(data))
    if (length(absent)) cli::cli_abort("Fatality columns not found: {absent}.")
    return(columns)
  }
  candidates <- list(
    c(low = "low", best = "best", high = "high"),
    c(low = "bd_low", best = "bd_best", high = "bd_high"),
    c(low = "deaths_low", best = "deaths_best", high = "deaths_high"),
    c(low = "fatalities_low", best = "fatalities_best", high = "fatalities_high")
  )
  for (candidate in candidates) {
    if (all(candidate %in% names(data))) return(candidate)
  }
  if (required) {
    cli::cli_abort(c(
      "Could not identify low, best, and high fatality columns.",
      "i" = "Supply their names explicitly."
    ))
  }
  NULL
}

fatality_values <- function(data, columns) {
  values <- lapply(columns, function(name) {
    raw <- data[[name]]
    value <- suppressWarnings(as.numeric(as.character(raw)))
    invalid <- !is.na(raw) & is.na(value)
    if (any(invalid)) {
      cli::cli_abort("Fatality column {.field {name}} contains non-numeric values.")
    }
    if (any(value < 0, na.rm = TRUE)) {
      cli::cli_abort("Fatality column {.field {name}} contains negative values.")
    }
    value
  })
  names(values) <- names(columns)
  complete <- stats::complete.cases(as.data.frame(values, optional = TRUE))
  invalid_bounds <- complete &
    (values$low > values$best | values$best > values$high)
  if (any(invalid_bounds)) {
    cli::cli_abort(c(
      "Fatality bounds are inconsistent in row(s): {which(invalid_bounds)}.",
      "i" = "Expected low <= best <= high."
    ))
  }
  values
}

sum_fatality <- function(x, na_rm) {
  if (!length(x) || all(is.na(x))) return(NA_real_)
  if (!na_rm && anyNA(x)) return(NA_real_)
  sum(x, na.rm = na_rm)
}

summarize_fatality_groups <- function(data, by, values, na_rm) {
  key <- if (length(by)) composite_key(data, by) else rep("all", nrow(data))
  keys <- unique(key)
  group_id <- match(key, keys)
  indices <- unname(split(
    seq_along(key), factor(group_id, levels = seq_along(keys))
  ))
  parts <- lapply(indices, function(rows) {
    groups <- if (length(by)) data[rows[[1L]], by, drop = FALSE] else NULL
    complete <- stats::complete.cases(as.data.frame(
      lapply(values, `[`, rows), optional = TRUE
    ))
    metrics <- data.frame(
      n_observations = length(rows),
      n_complete = sum(complete),
      n_missing = sum(!complete),
      fatalities_low = sum_fatality(values$low[rows], na_rm),
      fatalities_best = sum_fatality(values$best[rows], na_rm),
      fatalities_high = sum_fatality(values$high[rows], na_rm),
      stringsAsFactors = FALSE
    )
    if (length(by)) cbind(groups, metrics) else metrics
  })
  tibble::as_tibble(do.call(rbind, parts))
}

normalize_aggregation_unit <- function(unit) {
  if (!is.character(unit) || length(unit) != 1L || is.na(unit) || !nzchar(unit)) {
    cli::cli_abort("{.arg unit} must be one non-empty character string.")
  }
  unit <- gsub("_", "-", tolower(unit), fixed = TRUE)
  choices <- as.vector(outer(
    c("country", "grid", "conflict", "dyad"), c("year", "month"),
    paste, sep = "-"
  ))
  if (!unit %in% choices) {
    cli::cli_abort(c(
      "Unsupported aggregation {.arg unit}: {.val {unit}}.",
      "i" = "Choose one of: {paste(choices, collapse = ', ')}."
    ))
  }
  unit
}

resolve_aggregation_spec <- function(data, unit, id, date, by) {
  unit <- normalize_aggregation_unit(unit)
  pieces <- strsplit(unit, "-", fixed = TRUE)[[1L]]
  entity_type <- pieces[[1L]]
  period <- pieces[[2L]]
  entity <- if (is.null(id)) {
    detect_entity_columns(data, entity_type)
  } else {
    aggregation_columns(data, id, "id")
  }
  by <- aggregation_columns(data, by, "by")
  overlap <- intersect(entity, by)
  if (length(overlap)) cli::cli_abort("{.arg id} and {.arg by} overlap: {overlap}.")
  if (any(c("year", "month") %in% c(entity, by))) {
    cli::cli_abort("Time columns must not be included in {.arg id} or {.arg by}.")
  }
  time <- aggregation_time(data, period, date)
  list(
    unit = unit, entity = entity, by = by, period = period,
    year = time$year, month = time$month
  )
}

detect_entity_columns <- function(data, type) {
  candidates <- switch(type,
    country = list(c("country_id", "country"), c("gwno_loc", "location"),
                   "country_id", "gwno_loc", "country", "location"),
    grid = list("priogrid_gid", "gid", "priogrid_id", "pgid"),
    conflict = list("conflict_id"),
    dyad = list("dyad_id")
  )
  for (candidate in candidates) {
    if (all(candidate %in% names(data))) return(candidate)
  }
  cli::cli_abort(c(
    "Could not identify the {type} entity column.",
    "i" = "Supply the column name or names with {.arg id}."
  ))
}

aggregation_time <- function(data, period, date) {
  if (period == "year" && "year" %in% names(data)) {
    return(list(year = integer_time(data$year, "year"), month = NULL))
  }
  if (period == "month" && all(c("year", "month") %in% names(data))) {
    year <- integer_time(data$year, "year")
    month <- integer_time(data$month, "month")
    if (any(month < 1L | month > 12L, na.rm = TRUE)) {
      cli::cli_abort("{.field month} values must lie between 1 and 12.")
    }
    return(list(year = year, month = month))
  }
  if (is.null(date)) {
    candidates <- c("date_start", "date", "event_date")
    found <- candidates[candidates %in% names(data)]
    if (!length(found)) {
      cli::cli_abort(c(
        "Could not derive the aggregation period.",
        "i" = "Supply {.arg date}, or include suitable year/month columns."
      ))
    }
    date <- found[[1L]]
  }
  date <- aggregation_columns(data, date, "date")
  if (length(date) != 1L) cli::cli_abort("{.arg date} must name one column.")
  parsed <- parse_aggregation_date(data[[date]], date)
  list(
    year = as.integer(format(parsed, "%Y")),
    month = if (period == "month") as.integer(format(parsed, "%m")) else NULL
  )
}

integer_time <- function(x, name) {
  numeric <- suppressWarnings(as.numeric(as.character(x)))
  invalid <- !is.na(x) & (is.na(numeric) | numeric != floor(numeric))
  if (any(invalid)) cli::cli_abort("{.field {name}} must contain whole numbers.")
  as.integer(numeric)
}

parse_aggregation_date <- function(x, name) {
  value <- if (inherits(x, "Date")) {
    x
  } else if (inherits(x, c("POSIXct", "POSIXlt"))) {
    as.Date(x)
  } else {
    suppressWarnings(as.Date(as.character(x)))
  }
  invalid <- !is.na(x) & is.na(value)
  if (any(invalid)) cli::cli_abort("Date column {.field {name}} contains invalid dates.")
  value
}

complete_group_rows <- function(data, groups) {
  if (!length(groups)) return(rep(TRUE, nrow(data)))
  stats::complete.cases(data[groups])
}

summarize_aggregation_groups <- function(data, groups, fatalities, na_rm) {
  key <- composite_key(data, groups)
  keys <- unique(key)
  group_id <- match(key, keys)
  indices <- unname(split(
    seq_along(key), factor(group_id, levels = seq_along(keys))
  ))
  parts <- lapply(indices, function(rows) {
    group <- data[rows[[1L]], groups, drop = FALSE]
    metrics <- data.frame(n_events = length(rows))
    if (!is.null(fatalities)) {
      complete <- stats::complete.cases(as.data.frame(
        lapply(fatalities, `[`, rows), optional = TRUE
      ))
      metrics$n_fatality_complete <- sum(complete)
      metrics$n_fatality_missing <- sum(!complete)
      metrics$fatalities_low <- sum_fatality(fatalities$low[rows], na_rm)
      metrics$fatalities_best <- sum_fatality(fatalities$best[rows], na_rm)
      metrics$fatalities_high <- sum_fatality(fatalities$high[rows], na_rm)
    }
    cbind(group, metrics)
  })
  tibble::as_tibble(do.call(rbind, parts))
}

panel_universe <- function(data, entity, universe) {
  if (is.null(universe)) return(unique(data[entity]))
  if (is.data.frame(universe)) {
    absent <- setdiff(entity, names(universe))
    if (length(absent)) cli::cli_abort("{.arg universe} is missing columns: {absent}.")
    out <- unique(universe[entity])
  } else {
    if (length(entity) != 1L) {
      cli::cli_abort("A vector {.arg universe} requires a one-column entity key.")
    }
    out <- data.frame(universe, stringsAsFactors = FALSE)
    names(out) <- entity
  }
  if (!nrow(out) || anyNA(out)) {
    cli::cli_abort("{.arg universe} must contain non-missing entity combinations.")
  }
  out
}

panel_periods <- function(data, period, start, end) {
  if (period == "year") {
    observed <- integer_time(data$year, "year")
    first <- if (is.null(start)) min(observed) else panel_year(start, "start")
    last <- if (is.null(end)) max(observed) else panel_year(end, "end")
    if (first > last) cli::cli_abort("{.arg start} must not be later than {.arg end}.")
    return(data.frame(year = seq.int(first, last)))
  }
  observed <- as.Date(sprintf("%04d-%02d-01", data$year, data$month))
  first <- if (is.null(start)) min(observed) else panel_month(start, "start")
  last <- if (is.null(end)) max(observed) else panel_month(end, "end")
  if (first > last) cli::cli_abort("{.arg start} must not be later than {.arg end}.")
  sequence <- seq(first, last, by = "month")
  data.frame(
    year = as.integer(format(sequence, "%Y")),
    month = as.integer(format(sequence, "%m"))
  )
}

panel_year <- function(x, argument) {
  if (length(x) != 1L || is.na(x)) cli::cli_abort("{.arg {argument}} must be one year.")
  value <- suppressWarnings(as.numeric(as.character(x)))
  if (is.na(value) || value != floor(value) || value < 1000 || value > 9999) {
    cli::cli_abort("{.arg {argument}} must be a four-digit year.")
  }
  as.integer(value)
}

panel_month <- function(x, argument) {
  if (length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {argument}} must be one month boundary.")
  }
  if (inherits(x, "Date")) return(as.Date(format(x, "%Y-%m-01")))
  text <- as.character(x)
  if (grepl("^[0-9]{4}-[0-9]{2}$", text)) text <- paste0(text, "-01")
  value <- suppressWarnings(as.Date(text))
  if (is.na(value)) cli::cli_abort("{.arg {argument}} must use YYYY-MM or a valid date.")
  as.Date(format(value, "%Y-%m-01"))
}

cross_panel <- function(entities, periods) {
  entity_rows <- rep(seq_len(nrow(entities)), each = nrow(periods))
  period_rows <- rep(seq_len(nrow(periods)), times = nrow(entities))
  cbind(
    entities[entity_rows, , drop = FALSE],
    periods[period_rows, , drop = FALSE]
  )
}
