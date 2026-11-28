#' Inventory uncertainty-related information in UCDP data
#'
#' `ucdp_uncertainty()` summarizes fatality bounds, missing fatality estimates,
#' and spatial and temporal precision codes. These dimensions remain separate:
#' the function does not combine them into an undocumented uncertainty score.
#'
#' @param data A data frame containing UCDP observations.
#' @param by Optional grouping columns.
#' @param low,best,high Optional fatality-bound columns. Supply all three or
#'   none.
#' @param where_prec,date_prec Optional spatial and temporal precision columns.
#'   Set either argument to `NA_character_` to omit that dimension. Common UCDP
#'   names are detected when the argument is `NULL`.
#' @return A tidy tibble with grouping columns, uncertainty dimension, metric,
#'   value, and group size. Source metadata and detected column mappings are
#'   attached as attributes.
#' @export
#' @examples
#' events <- data.frame(
#'   year = c(2020, 2020, 2021),
#'   low = c(1, 2, NA), best = c(2, 3, 4), high = c(3, 5, 6),
#'   where_prec = c(1, 2, 6), date_prec = c(1, 2, 4)
#' )
#' ucdp_uncertainty(events)
#' ucdp_uncertainty(events, by = "year")
ucdp_uncertainty <- function(data, by = NULL, low = NULL, best = NULL,
                             high = NULL, where_prec = NULL,
                             date_prec = NULL) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  source <- attr(data, "ucdp_source", exact = TRUE)
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  by <- aggregation_columns(data, by, "by")
  fatality_columns <- resolve_fatality_columns(
    data, low, best, high, required = any(!vapply(
      list(low, best, high), is.null, logical(1)
    ))
  )
  precision_columns <- c(
    spatial = uncertainty_precision_column(data, where_prec, "where_prec"),
    temporal = uncertainty_precision_column(data, date_prec, "date_prec")
  )
  precision_columns <- precision_columns[!is.na(precision_columns)]
  if (is.null(fatality_columns) && !length(precision_columns)) {
    cli::cli_abort(c(
      "No supported uncertainty information was found in {.arg data}.",
      "i" = "Supply fatality or precision column names explicitly."
    ))
  }

  groups <- uncertainty_groups(data, by)
  parts <- lapply(groups, function(rows) {
    group <- if (length(by)) data[rows[[1L]], by, drop = FALSE] else NULL
    metrics <- list()
    if (!is.null(fatality_columns)) {
      values <- fatality_values(data[rows, , drop = FALSE], fatality_columns)
      complete <- stats::complete.cases(as.data.frame(values, optional = TRUE))
      observed <- Reduce(`+`, lapply(values, function(x) !is.na(x)))
      width <- values$high - values$low
      metrics[[length(metrics) + 1L]] <- uncertainty_metric_rows(
        "fatality", c(
          n_complete = sum(complete),
          n_partial = sum(observed > 0L & observed < 3L),
          n_all_missing = sum(observed == 0L),
          share_complete = mean(complete),
          mean_bound_width = uncertainty_stat(width, mean),
          median_bound_width = uncertainty_stat(width, stats::median)
        ), length(rows)
      )
    }
    for (dimension in names(precision_columns)) {
      column <- precision_columns[[dimension]]
      parsed <- strict_integer_parse(data[[column]][rows])
      if (any(parsed$invalid)) {
        cli::cli_abort(
          "{.field {column}} contains non-integer values in rows: {rows[parsed$invalid]}."
        )
      }
      value <- parsed$value
      metrics[[length(metrics) + 1L]] <- uncertainty_metric_rows(
        dimension, c(
          n_missing = sum(is.na(value)),
          n_exact = sum(value == 1L, na.rm = TRUE),
          share_exact = if (all(is.na(value))) NA_real_ else mean(value == 1L, na.rm = TRUE),
          mean_code = uncertainty_stat(value, mean),
          maximum_code = uncertainty_stat(value, max)
        ), length(rows)
      )
    }
    result <- do.call(rbind, metrics)
    if (length(by)) {
      result <- cbind(group[rep(1L, nrow(result)), , drop = FALSE], result)
    }
    result
  })
  out <- tibble::as_tibble(do.call(rbind, parts))
  class(out) <- unique(c("ucdp_uncertainty", class(out)))
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_uncertainty_columns") <- list(
    fatalities = fatality_columns, precision = precision_columns
  )
  out
}

#' Construct low, best, and high fatality scenarios
#'
#' `ucdp_scenarios()` retains UCDP's three reported fatality estimates as
#' explicit analytical scenarios. They are not interpreted as probability or
#' confidence intervals.
#'
#' @param data A data frame containing fatality estimates.
#' @param by Optional grouping columns. When supplied, fatalities are summed
#'   within groups before scenarios are constructed.
#' @param low,best,high Optional fatality-bound columns.
#' @param format Return scenarios in long or wide form.
#' @param fatality_missing Missing-value policy used for grouped sums. See
#'   [ucdp_fatalities()]. For ungrouped data, `"error"` rejects missing bounds;
#'   other policies retain them.
#' @return A tibble with explicit scenario metadata and preserved provenance.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:3, year = c(2020, 2020, 2021),
#'   low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 5, 6)
#' )
#' ucdp_scenarios(events)
#' ucdp_scenarios(events, by = "year", format = "wide")
ucdp_scenarios <- function(data, by = NULL, low = NULL, best = NULL,
                           high = NULL, format = c("long", "wide"),
                           fatality_missing = c("propagate", "remove", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  format <- match.arg(format)
  fatality_missing <- match.arg(fatality_missing)
  source <- attr(data, "ucdp_source", exact = TRUE)
  original <- as.data.frame(data, stringsAsFactors = FALSE)
  by <- aggregation_columns(original, by, "by")
  columns <- resolve_fatality_columns(original, low, best, high, required = TRUE)

  if (length(by)) {
    wide <- ucdp_fatalities(
      original, by = by, low = columns[["low"]], best = columns[["best"]],
      high = columns[["high"]], fatality_missing = fatality_missing
    )
    key_columns <- setdiff(
      names(wide), c("fatalities_low", "fatalities_best", "fatalities_high")
    )
  } else {
    values <- fatality_values(original, columns)
    if (fatality_missing == "error") check_fatality_missing(values, "error")
    key_columns <- setdiff(names(original), unname(columns))
    wide <- cbind(
      original[key_columns],
      data.frame(
        fatalities_low = values$low,
        fatalities_best = values$best,
        fatalities_high = values$high,
        stringsAsFactors = FALSE
      )
    )
    wide <- tibble::as_tibble(wide)
  }

  if (format == "wide") {
    out <- wide
  } else {
    scenario_names <- c("low", "best", "high")
    parts <- lapply(scenario_names, function(scenario) {
      result <- wide[key_columns]
      result$fatality_scenario <- scenario
      result$fatalities <- wide[[paste0("fatalities_", scenario)]]
      result
    })
    out <- tibble::as_tibble(do.call(rbind, parts))
  }
  class(out) <- unique(c("ucdp_scenarios", class(out)))
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_scenario_spec") <- list(
    format = format, by = by, fatality_columns = columns,
    fatality_missing = fatality_missing,
    interpretation = "UCDP bounds treated as analytical scenarios, not probability intervals"
  )
  out
}

#' Sample assumption-based fatality realizations within UCDP bounds
#'
#' `ucdp_sample_fatalities()` is experimental. UCDP low and high estimates do
#' not define a probability distribution; every draw produced here reflects
#' the analyst-selected uniform or triangular assumption.
#'
#' @param data A data frame containing low, best, and high fatalities.
#' @param n Number of realizations per observation.
#' @param distribution Sampling assumption. The triangular distribution uses
#'   the best estimate as its mode.
#' @param low,best,high Optional fatality-bound columns.
#' @param seed Optional non-negative integer seed. When supplied, the caller's
#'   existing random-number state is restored after sampling.
#' @param id Optional observation-identifier columns. A stable row number is
#'   created when omitted.
#' @param format Return one long tibble or a list containing one data frame per
#'   realization.
#' @param missing How to handle incomplete fatality triplets.
#' @return A tibble or list with sampled fatalities and recorded assumptions.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:2, low = c(1, 4), best = c(2, 5), high = c(3, 8)
#' )
#' ucdp_sample_fatalities(events, n = 3, seed = 42)
ucdp_sample_fatalities <- function(
    data, n = 100L, distribution = c("uniform", "triangular"),
    low = NULL, best = NULL, high = NULL, seed = NULL, id = NULL,
    format = c("long", "list"), missing = c("error", "propagate", "drop")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  n <- uncertainty_positive_integer(n, "n")
  seed <- uncertainty_seed(seed)
  distribution <- match.arg(distribution)
  format <- match.arg(format)
  missing <- match.arg(missing)
  source <- attr(data, "ucdp_source", exact = TRUE)
  original <- as.data.frame(data, stringsAsFactors = FALSE)
  id <- if (is.null(id)) character() else aggregation_columns(original, id, "id")
  columns <- resolve_fatality_columns(original, low, best, high, required = TRUE)
  values <- fatality_values(original, columns)
  incomplete <- !stats::complete.cases(as.data.frame(values, optional = TRUE))
  if (missing == "error" && any(incomplete)) {
    cli::cli_abort("Incomplete fatality bounds occur in rows: {which(incomplete)}.")
  }
  keep <- if (missing == "drop") !incomplete else rep(TRUE, nrow(original))
  original <- original[keep, , drop = FALSE]
  values <- lapply(values, `[`, keep)
  if (!nrow(original)) {
    cli::cli_abort(
      "No observations remain after dropping incomplete fatality bounds."
    )
  }
  uncertainty_integer_triplet(values)

  sampled <- with_uncertainty_seed(seed, function() {
    matrix <- vapply(seq_len(nrow(original)), function(i) {
      if (anyNA(c(values$low[[i]], values$best[[i]], values$high[[i]]))) {
        return(rep(NA_integer_, n))
      }
      sample_fatality_row(
        n, values$low[[i]], values$best[[i]], values$high[[i]], distribution
      )
    }, integer(n))
    if (nrow(original) == 1L) matrix <- base::matrix(matrix, ncol = 1L)
    matrix
  })

  identifiers <- if (length(id)) original[id] else data.frame(
    .ucdp_row = which(keep), stringsAsFactors = FALSE
  )
  if (format == "long") {
    out <- identifiers[rep(seq_len(nrow(identifiers)), each = n), , drop = FALSE]
    out$.draw <- rep(seq_len(n), times = nrow(identifiers))
    out$fatalities <- as.integer(as.vector(sampled))
    out <- tibble::as_tibble(out)
  } else {
    out <- lapply(seq_len(n), function(draw) {
      result <- original
      result$.ucdp_sampled_fatalities <- sampled[draw, ]
      tibble::as_tibble(result)
    })
    names(out) <- paste0("draw_", seq_len(n))
  }
  class(out) <- unique(c("ucdp_fatality_samples", class(out)))
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_sampling_spec") <- list(
    n = n, distribution = distribution, seed = seed, id = id,
    fatality_columns = columns, missing = missing,
    interpretation = "Analyst-assumed distribution within UCDP bounds"
  )
  out
}

#' Evaluate UCDP results across explicit analytical assumptions
#'
#' `ucdp_sensitivity()` applies fatality scenarios and optional precision
#' filters to a common data set. It can return each transformed data set or
#' apply a user-supplied analysis function to every specification.
#'
#' @param data A data frame containing fatality bounds.
#' @param scenarios Any of `"low"`, `"best"`, and `"high"`.
#' @param where_prec,date_prec Precision specifications. Supply `NULL`, one
#'   vector of accepted codes, or a named list of alternative code vectors.
#' @param fatality_missing Missing-value policy applied to fatality bounds.
#'   `"remove"` excludes observations with incomplete triplets before the
#'   sensitivity grid is evaluated.
#' @param analysis Optional function whose first argument receives a transformed
#'   data frame containing `.ucdp_fatalities`.
#' @param ... Additional arguments passed to `analysis`.
#' @param error Should analysis errors stop immediately or be recorded?
#' @param precision_missing Missing-value policy passed to
#'   [ucdp_filter_precision()].
#' @return An object with a specification table, result table, and, when
#'   `analysis = NULL`, the transformed data sets.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:3, low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 5, 6),
#'   where_prec = c(1, 2, 6)
#' )
#' sensitivity <- ucdp_sensitivity(
#'   events,
#'   where_prec = list(all = NULL, precise = 1:2),
#'   analysis = function(x) c(total = sum(x$.ucdp_fatalities))
#' )
#' sensitivity$results
ucdp_sensitivity <- function(
    data, scenarios = c("low", "best", "high"), where_prec = NULL,
    date_prec = NULL, fatality_missing = c("propagate", "remove", "error"),
    analysis = NULL, ..., error = c("stop", "record"),
    precision_missing = c("drop", "keep", "error")) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  scenarios <- uncertainty_scenarios(scenarios)
  fatality_missing <- match.arg(fatality_missing)
  error <- match.arg(error)
  precision_missing <- match.arg(precision_missing)
  if (!is.null(analysis) && !is.function(analysis)) {
    cli::cli_abort("{.arg analysis} must be a function or NULL.")
  }
  spatial <- uncertainty_filter_specs(where_prec, "where_prec")
  temporal <- uncertainty_filter_specs(date_prec, "date_prec")
  source <- attr(data, "ucdp_source", exact = TRUE)
  columns <- resolve_fatality_columns(data, NULL, NULL, NULL, required = TRUE)
  values <- fatality_values(data, columns)
  if (fatality_missing == "error") check_fatality_missing(values, "error")
  if (fatality_missing == "remove") {
    complete <- stats::complete.cases(as.data.frame(values, optional = TRUE))
    data <- data[complete, , drop = FALSE]
    if (!nrow(data)) {
      cli::cli_abort(
        "No observations remain after removing incomplete fatality bounds."
      )
    }
  }

  specifications <- list()
  transformed <- list()
  result_parts <- list()
  index <- 0L
  for (scenario in scenarios) for (spatial_index in seq_along(spatial)) {
    for (temporal_index in seq_along(temporal)) {
      index <- index + 1L
      spatial_spec <- spatial[[spatial_index]]
      temporal_spec <- temporal[[temporal_index]]
      filtered <- ucdp_filter_precision(
        data, where_prec = spatial_spec$value,
        date_prec = temporal_spec$value, missing = precision_missing
      )
      selected <- uncertainty_select_scenario(filtered, scenario)
      specification <- data.frame(
        .specification = index,
        .scenario = scenario,
        .where_precision = spatial_spec$label,
        .date_precision = temporal_spec$label,
        n_rows = nrow(selected),
        status = "ok",
        error = NA_character_,
        stringsAsFactors = FALSE
      )
      if (is.null(analysis)) {
        transformed[[index]] <- tibble::as_tibble(selected)
      } else {
        evaluated <- tryCatch({
          value <- analysis(selected, ...)
          uncertainty_analysis_result(value, specification)
        }, error = function(e) e)
        if (inherits(evaluated, "error")) {
          if (error == "stop") cli::cli_abort(
            c("Sensitivity analysis failed for specification {index}.",
              "i" = conditionMessage(evaluated)), parent = evaluated
          )
          specification$status <- "error"
          specification$error <- conditionMessage(evaluated)
        } else {
          result_parts[[length(result_parts) + 1L]] <- evaluated
        }
      }
      specifications[[index]] <- specification
    }
  }
  specification_table <- tibble::as_tibble(do.call(rbind, specifications))
  results <- if (length(result_parts)) {
    uncertainty_bind_rows(result_parts)
  } else {
    tibble::tibble()
  }
  out <- list(
    specifications = specification_table,
    results = results,
    data = if (is.null(analysis)) transformed else NULL
  )
  class(out) <- "ucdp_sensitivity"
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_sensitivity_spec") <- list(
    scenarios = scenarios, fatality_missing = fatality_missing,
    precision_missing = precision_missing, analysis = !is.null(analysis)
  )
  out
}

#' Compare fatality scenarios or sensitivity results
#'
#' @param x Long output from [ucdp_scenarios()] or an analyzed
#'   `ucdp_sensitivity` object.
#' @param reference Reference scenario.
#' @param value Numeric result column. It is detected only when unambiguous.
#' @param by Optional comparison-key columns. By default, all non-result,
#'   non-scenario specification columns are used.
#' @param relative Include relative differences from the reference?
#' @return A tibble containing scenario values, reference values, and absolute
#'   and optional relative differences.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:2, low = c(1, 2), best = c(2, 3), high = c(4, 5)
#' )
#' scenarios <- ucdp_scenarios(events)
#' ucdp_compare_scenarios(scenarios, by = "id")
ucdp_compare_scenarios <- function(x, reference = "best", value = NULL,
                                   by = NULL, relative = TRUE) {
  validate_flag(relative, "relative")
  source <- attr(x, "ucdp_source", exact = TRUE)
  if (inherits(x, "ucdp_sensitivity")) {
    data <- x$results
    scenario_column <- ".scenario"
    ignored <- c(".specification", "n_rows", "status", "error")
  } else if (is.data.frame(x)) {
    data <- x
    scenario_column <- "fatality_scenario"
    ignored <- character()
  } else {
    cli::cli_abort(
      "{.arg x} must be scenario data or an analyzed {.cls ucdp_sensitivity} object."
    )
  }
  if (!nrow(data)) cli::cli_abort("{.arg x} does not contain comparison results.")
  if (!scenario_column %in% names(data)) {
    cli::cli_abort("Scenario column {.field {scenario_column}} is missing.")
  }
  reference <- uncertainty_one_string(reference, "reference")
  if (!reference %in% data[[scenario_column]]) {
    cli::cli_abort("Reference scenario {.val {reference}} is not present.")
  }
  value <- uncertainty_value_column(data, value, scenario_column, ignored)
  if (is.null(by)) {
    by <- setdiff(names(data), c(scenario_column, value, ignored))
    if (inherits(x, "ucdp_sensitivity")) {
      by <- by[!vapply(data[by], is.numeric, logical(1))]
    }
  } else {
    by <- aggregation_columns(data, by, "by")
  }
  key <- if (length(by)) composite_key(data, by) else rep("all", nrow(data))
  pair_key <- paste(key, data[[scenario_column]], sep = "\r")
  if (anyDuplicated(pair_key)) {
    cli::cli_abort("Scenario keys are duplicated; refine {.arg by}.")
  }
  reference_rows <- data[[scenario_column]] == reference
  reference_key <- key[reference_rows]
  reference_value <- data[[value]][reference_rows]
  matched <- match(key, reference_key)
  if (anyNA(matched)) {
    cli::cli_abort("A reference value is missing for one or more comparison keys.")
  }
  out <- data[c(by, scenario_column, value)]
  out$reference_scenario <- reference
  out$reference_value <- reference_value[matched]
  out$difference <- data[[value]] - out$reference_value
  if (relative) {
    out$relative_difference <- ifelse(
      is.na(out$reference_value), NA_real_,
      ifelse(out$reference_value == 0,
             ifelse(data[[value]] == 0, 0, NA_real_),
             out$difference / abs(out$reference_value))
    )
  }
  out <- tibble::as_tibble(out)
  class(out) <- unique(c("ucdp_scenario_comparison", class(out)))
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_comparison_spec") <- list(
    reference = reference, value = value, by = by, relative = relative
  )
  out
}

#' Prepare UCDP event data for uncertainUCDP
#'
#' `ucdp_to_uncertainUCDP()` validates and adds the vectors expected by
#' `uncertainUCDP` 0.7.6: reported fatalities and a violence-type code. It does
#' not call or reproduce that package's statistical model.
#'
#' @param data Event-level UCDP data.
#' @param fatalities Reported-fatality column. Common best-estimate columns are
#'   detected when omitted.
#' @param type_of_violence Violence-type column. Common UCDP names are detected
#'   when omitted.
#' @param missing How to handle rows with missing fatalities or violence type.
#' @param check_package If `uncertainUCDP` is installed, verify that its version
#'   is at least 0.7.6.
#' @return A tibble retaining the original columns and adding
#'   `.ucdp_fatalities` and `.ucdp_tov`.
#' @export
#' @examples
#' events <- data.frame(
#'   id = 1:3, best = c(2, 5, 1), type_of_violence = c(1, 2, 3)
#' )
#' prepared <- ucdp_to_uncertainUCDP(events, check_package = FALSE)
#' prepared[c(".ucdp_fatalities", ".ucdp_tov")]
ucdp_to_uncertainUCDP <- function(
    data, fatalities = NULL, type_of_violence = NULL,
    missing = c("error", "drop", "keep"), check_package = TRUE) {
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
  if (!nrow(data)) cli::cli_abort("{.arg data} must contain at least one row.")
  missing <- match.arg(missing)
  validate_flag(check_package, "check_package")
  if (check_package && requireNamespace("uncertainUCDP", quietly = TRUE) &&
      utils::packageVersion("uncertainUCDP") < "0.7.6") {
    cli::cli_abort("Install {.pkg uncertainUCDP} version 0.7.6 or later.")
  }
  source <- attr(data, "ucdp_source", exact = TRUE)
  original <- as.data.frame(data, stringsAsFactors = FALSE)
  fatalities <- uncertainty_detect_column(
    original, fatalities, c("best", "bd_best", "fatalities_best"), "fatalities"
  )
  type_of_violence <- uncertainty_detect_column(
    original, type_of_violence,
    c("type_of_violence", "violence_type"),
    "type_of_violence"
  )
  fatality_value <- suppressWarnings(as.numeric(as.character(original[[fatalities]])))
  invalid_fatality <- !is.na(original[[fatalities]]) & (
    is.na(fatality_value) | !is.finite(fatality_value) |
      fatality_value < 0 | fatality_value != floor(fatality_value)
  )
  if (any(invalid_fatality)) {
    cli::cli_abort(
      "{.field {fatalities}} must contain non-negative integer fatalities; invalid rows: {which(invalid_fatality)}."
    )
  }
  tov <- uncertainty_tov(original[[type_of_violence]])
  incomplete <- is.na(fatality_value) | is.na(tov)
  if (missing == "error" && any(incomplete)) {
    cli::cli_abort("Missing uncertainUCDP inputs occur in rows: {which(incomplete)}.")
  }
  if (missing == "drop") {
    original <- original[!incomplete, , drop = FALSE]
    fatality_value <- fatality_value[!incomplete]
    tov <- tov[!incomplete]
  }
  original$.ucdp_fatalities <- fatality_value
  original$.ucdp_tov <- tov
  out <- tibble::as_tibble(original)
  class(out) <- unique(c("ucdp_uncertainUCDP", class(out)))
  if (!is.null(source)) attr(out, "ucdp_source") <- source
  attr(out, "ucdp_uncertainUCDP_mapping") <- list(
    fatalities = fatalities, type_of_violence = type_of_violence,
    target_version = ">= 0.7.6"
  )
  out
}

uncertainty_precision_column <- function(data, supplied, default) {
  if (length(supplied) == 1L && is.character(supplied) && is.na(supplied)) {
    return(NA_character_)
  }
  if (is.null(supplied)) return(if (default %in% names(data)) default else NA_character_)
  uncertainty_detect_column(data, supplied, character(), default)
}

uncertainty_detect_column <- function(data, supplied, candidates, argument) {
  if (is.null(supplied)) {
    found <- candidates[candidates %in% names(data)]
    if (!length(found)) cli::cli_abort(c(
      "Could not identify the {.field {argument}} column.",
      "i" = "Supply its name explicitly."
    ))
    return(found[[1L]])
  }
  supplied <- uncertainty_one_string(supplied, argument)
  if (!supplied %in% names(data)) {
    cli::cli_abort("Column {.field {supplied}} was not found in {.arg data}.")
  }
  supplied
}

uncertainty_one_string <- function(x, argument) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort("{.arg {argument}} must be one non-empty character string.")
  }
  x
}

uncertainty_groups <- function(data, by) {
  key <- if (length(by)) composite_key(data, by) else rep("all", nrow(data))
  group_id <- match(key, unique(key))
  unname(split(seq_along(key), factor(group_id, levels = unique(group_id))))
}

uncertainty_metric_rows <- function(dimension, values, n) {
  data.frame(
    dimension = dimension,
    metric = names(values),
    value = as.numeric(values),
    n_observations = as.integer(n),
    stringsAsFactors = FALSE
  )
}

uncertainty_stat <- function(x, fun) {
  if (!length(x) || all(is.na(x))) return(NA_real_)
  as.numeric(fun(x, na.rm = TRUE))
}

uncertainty_positive_integer <- function(x, argument) {
  parsed <- strict_integer_parse(x)
  if (length(x) != 1L || any(parsed$invalid) || is.na(parsed$value) || parsed$value < 1L) {
    cli::cli_abort("{.arg {argument}} must be one positive integer.")
  }
  parsed$value[[1L]]
}

uncertainty_seed <- function(seed) {
  if (is.null(seed)) return(NULL)
  parsed <- strict_integer_parse(seed)
  if (length(seed) != 1L || any(parsed$invalid) || is.na(parsed$value) || parsed$value < 0L) {
    cli::cli_abort("{.arg seed} must be NULL or one non-negative integer.")
  }
  parsed$value[[1L]]
}

uncertainty_integer_triplet <- function(values) {
  for (name in names(values)) {
    invalid <- !is.na(values[[name]]) & (
      values[[name]] != floor(values[[name]]) |
        values[[name]] > .Machine$integer.max
    )
    if (any(invalid)) {
      cli::cli_abort("Fatality bound {.field {name}} must contain whole numbers.")
    }
  }
  invisible(values)
}

with_uncertainty_seed <- function(seed, code) {
  if (is.null(seed)) return(code())
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  code()
}

sample_fatality_row <- function(n, low, best, high, distribution) {
  low <- as.integer(low)
  best <- as.integer(best)
  high <- as.integer(high)
  if (low == high) return(rep(low, n))
  if (distribution == "uniform") {
    return(sample.int(high - low + 1L, n, replace = TRUE) + low - 1L)
  }
  probability <- stats::runif(n)
  split <- (best - low) / (high - low)
  value <- ifelse(
    probability < split,
    low + sqrt(probability * (high - low) * (best - low)),
    high - sqrt((1 - probability) * (high - low) * (high - best))
  )
  as.integer(pmin(high, pmax(low, floor(value + 0.5))))
}

uncertainty_scenarios <- function(scenarios) {
  if (!is.character(scenarios) || !length(scenarios) || anyNA(scenarios)) {
    cli::cli_abort("{.arg scenarios} must contain scenario names.")
  }
  scenarios <- unique(tolower(scenarios))
  invalid <- setdiff(scenarios, c("low", "best", "high"))
  if (length(invalid)) cli::cli_abort("Unsupported scenarios: {invalid}.")
  scenarios
}

uncertainty_filter_specs <- function(x, argument) {
  if (is.null(x)) return(list(list(label = "all", value = NULL)))
  if (!is.list(x)) return(list(list(label = "selected", value = x)))
  if (!length(x)) cli::cli_abort("{.arg {argument}} must not be an empty list.")
  labels <- names(x)
  if (is.null(labels) || any(!nzchar(labels))) labels <- paste0("spec_", seq_along(x))
  lapply(seq_along(x), function(i) list(label = labels[[i]], value = x[[i]]))
}

uncertainty_select_scenario <- function(data, scenario) {
  columns <- resolve_fatality_columns(data, NULL, NULL, NULL, required = TRUE)
  value <- fatality_values(data, columns)[[scenario]]
  out <- as.data.frame(data, stringsAsFactors = FALSE)
  out$.ucdp_fatalities <- value
  attr(out, "ucdp_source") <- attr(data, "ucdp_source", exact = TRUE)
  attr(out, "ucdp_scenario") <- scenario
  out
}

uncertainty_analysis_result <- function(value, specification) {
  prefix <- specification[c(
    ".specification", ".scenario", ".where_precision", ".date_precision"
  )]
  if (is.data.frame(value)) {
    result <- as.data.frame(value, stringsAsFactors = FALSE)
  } else if (is.atomic(value) && !is.null(names(value)) && all(nzchar(names(value)))) {
    result <- as.data.frame(as.list(value), stringsAsFactors = FALSE)
  } else if (is.atomic(value)) {
    result <- data.frame(.result = value, stringsAsFactors = FALSE)
  } else if (is.list(value) && !is.null(names(value)) &&
             all(lengths(value) == 1L)) {
    result <- as.data.frame(value, stringsAsFactors = FALSE)
  } else {
    cli::cli_abort(c(
      "{.arg analysis} returned an unsupported result.",
      "i" = "Return a data frame, atomic vector, or named list of scalar values."
    ))
  }
  cbind(prefix[rep(1L, nrow(result)), , drop = FALSE], result)
}

uncertainty_bind_rows <- function(parts) {
  names_all <- unique(unlist(lapply(parts, names), use.names = FALSE))
  normalized <- lapply(parts, function(part) {
    absent <- setdiff(names_all, names(part))
    for (name in absent) part[[name]] <- NA
    part[names_all]
  })
  tibble::as_tibble(do.call(rbind, normalized))
}

uncertainty_value_column <- function(data, value, scenario_column, ignored) {
  if (!is.null(value)) {
    value <- uncertainty_one_string(value, "value")
    if (!value %in% names(data) || !is.numeric(data[[value]])) {
      cli::cli_abort("{.arg value} must name one numeric result column.")
    }
    return(value)
  }
  if ("fatalities" %in% names(data) && is.numeric(data$fatalities)) return("fatalities")
  candidates <- setdiff(names(data)[vapply(data, is.numeric, logical(1))],
                        c(ignored, scenario_column))
  if (length(candidates) != 1L) {
    cli::cli_abort(c(
      "Could not identify one numeric result column.",
      "i" = "Supply its name with {.arg value}."
    ))
  }
  candidates[[1L]]
}

uncertainty_tov <- function(x) {
  text <- tolower(trimws(as.character(x)))
  mapping <- c(
    "1" = "sb", "sb" = "sb", "state-based" = "sb",
    "state based" = "sb", "statebased" = "sb",
    "2" = "ns", "ns" = "ns", "non-state" = "ns",
    "non state" = "ns", "nonstate" = "ns",
    "3" = "os", "os" = "os", "one-sided" = "os",
    "one sided" = "os", "onesided" = "os",
    "any" = "any"
  )
  out <- unname(mapping[text])
  out[is.na(x) | !nzchar(text)] <- NA_character_
  invalid <- !is.na(x) & nzchar(text) & is.na(out)
  if (any(invalid)) {
    cli::cli_abort(
      "Unsupported type-of-violence values in rows: {which(invalid)}."
    )
  }
  out
}
