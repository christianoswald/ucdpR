test_that("uncertainty inventory keeps dimensions separate", {
  x <- data.frame(
    year = c(2020, 2020, 2021),
    low = c(1, NA, NA), best = c(2, 3, NA), high = c(3, 5, NA),
    where_prec = c(1, 2, NA), date_prec = c(1, 4, 5)
  )
  attr(x, "ucdp_source") <- list(ucdp_version = "25.1")
  out <- ucdp_uncertainty(x)

  expect_s3_class(out, "ucdp_uncertainty")
  expect_named(out, c("dimension", "metric", "value", "n_observations"))
  expect_setequal(unique(out$dimension), c("fatality", "spatial", "temporal"))
  expect_equal(out$value[out$metric == "n_complete"], 1)
  expect_equal(out$value[out$metric == "n_partial"], 1)
  expect_equal(out$value[out$metric == "n_all_missing"], 1)
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "25.1")
})

test_that("uncertainty inventory supports groups and explicit omissions", {
  x <- data.frame(
    group = c("A", "A", "B"),
    low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 4, 5),
    where_prec = c(1, 2, 1)
  )
  out <- ucdp_uncertainty(x, by = "group", date_prec = NA_character_)
  expect_setequal(unique(out$group), c("A", "B"))
  expect_false("temporal" %in% out$dimension)
  expect_equal(unique(out$n_observations[out$group == "A"]), 2)
})

test_that("uncertainty inventory validates supported information", {
  expect_error(ucdp_uncertainty(data.frame(x = 1)), "No supported")
  expect_error(
    ucdp_uncertainty(data.frame(where_prec = 1.5)),
    "non-integer"
  )
  expect_error(
    ucdp_uncertainty(
      data.frame(lo = 1, mid = 2, hi = 3),
      low = "lo", best = "missing", high = "hi"
    ),
    "not found"
  )
})

test_that("fatality scenarios produce consistent long and wide data", {
  x <- data.frame(
    id = 1:2, low = c(1, 2), best = c(2, 3), high = c(3, 5)
  )
  long <- ucdp_scenarios(x)
  wide <- ucdp_scenarios(x, format = "wide")

  expect_s3_class(long, "ucdp_scenarios")
  expect_equal(nrow(long), 6)
  expect_equal(unique(long$fatality_scenario), c("low", "best", "high"))
  expect_equal(long$fatalities[long$fatality_scenario == "best"], wide$fatalities_best)
  expect_equal(wide$fatalities_high, c(3, 5))
})

test_that("grouped scenarios retain diagnostics and missingness policy", {
  x <- data.frame(
    year = c(2020, 2020), low = c(1, NA),
    best = c(2, 3), high = c(3, 4)
  )
  propagated <- ucdp_scenarios(x, by = "year", fatality_missing = "propagate")
  removed <- ucdp_scenarios(x, by = "year", fatality_missing = "remove")

  expect_true("n_missing" %in% names(propagated))
  expect_true(is.na(propagated$fatalities[propagated$fatality_scenario == "low"]))
  expect_equal(removed$fatalities[removed$fatality_scenario == "low"], 1)
  expect_error(
    ucdp_scenarios(x, by = "year", fatality_missing = "error"),
    "Missing fatality"
  )
})

test_that("scenario construction preserves provenance", {
  x <- data.frame(low = 1, best = 2, high = 3)
  attr(x, "ucdp_source") <- list(ucdp_version = "25.1")
  out <- ucdp_scenarios(x)
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "25.1")
  expect_match(
    attr(out, "ucdp_scenario_spec")$interpretation,
    "not probability"
  )
})

test_that("fatality sampling is bounded and reproducible", {
  x <- data.frame(
    id = 1:2, low = c(1, 4), best = c(2, 5), high = c(3, 8)
  )
  first <- ucdp_sample_fatalities(x, n = 20, seed = 42, id = "id")
  second <- ucdp_sample_fatalities(x, n = 20, seed = 42, id = "id")

  expect_s3_class(first, "ucdp_fatality_samples")
  expect_identical(first, second)
  expect_true(all(first$fatalities[first$id == 1] %in% 1:3))
  expect_true(all(first$fatalities[first$id == 2] %in% 4:8))
  expect_equal(sort(unique(first$.draw)), 1:20)

  implicit_id <- ucdp_sample_fatalities(x, n = 2, seed = 42)
  expect_equal(unique(implicit_id$.ucdp_row), 1:2)
})

test_that("fatality sampling restores an existing random state", {
  set.seed(123)
  state <- .Random.seed
  x <- data.frame(low = 1, best = 2, high = 3)
  invisible(ucdp_sample_fatalities(x, n = 5, seed = 9))
  expect_identical(.Random.seed, state)
})

test_that("fatality sampling handles degenerate and triangular bounds", {
  x <- data.frame(
    id = 1:2, low = c(2, 1), best = c(2, 4), high = c(2, 8)
  )
  out <- ucdp_sample_fatalities(
    x, n = 25, distribution = "triangular", seed = 1, id = "id"
  )
  expect_true(all(out$fatalities[out$id == 1] == 2))
  expect_true(all(out$fatalities[out$id == 2] >= 1))
  expect_true(all(out$fatalities[out$id == 2] <= 8))
})

test_that("fatality sampling supports list output and missing policies", {
  x <- data.frame(
    id = 1:2, low = c(1, NA), best = c(2, NA), high = c(3, NA)
  )
  expect_error(ucdp_sample_fatalities(x, n = 2), "Incomplete")
  kept <- ucdp_sample_fatalities(
    x, n = 2, missing = "propagate", seed = 1, id = "id"
  )
  dropped <- ucdp_sample_fatalities(
    x, n = 2, missing = "drop", format = "list", seed = 1
  )
  expect_true(all(is.na(kept$fatalities[kept$id == 2])))
  expect_length(dropped, 2)
  expect_equal(nrow(dropped[[1]]), 1)
  expect_true(".ucdp_sampled_fatalities" %in% names(dropped[[1]]))
})

test_that("fatality sampling reports when dropping removes every row", {
  all_missing <- data.frame(low = NA, best = NA, high = NA)
  expect_error(
    ucdp_sample_fatalities(all_missing, missing = "drop"),
    "No observations remain"
  )
})

test_that("fatality sampling validates integer bounds and controls", {
  expect_error(
    ucdp_sample_fatalities(
      data.frame(low = 1.2, best = 2, high = 3), n = 2
    ),
    "whole numbers"
  )
  expect_error(
    ucdp_sample_fatalities(data.frame(low = 1, best = 2, high = 3), n = 0),
    "positive integer"
  )
  expect_error(
    ucdp_sample_fatalities(
      data.frame(low = 1, best = 2, high = 3), seed = -1
    ),
    "non-negative integer"
  )
})

test_that("sensitivity analysis crosses scenarios and precision specifications", {
  x <- data.frame(
    id = 1:3, low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 5, 6),
    where_prec = c(1, 2, 6)
  )
  out <- ucdp_sensitivity(
    x, scenarios = c("low", "best"),
    where_prec = list(all = NULL, precise = 1:2),
    analysis = function(data) c(total = sum(data$.ucdp_fatalities))
  )
  expect_s3_class(out, "ucdp_sensitivity")
  expect_equal(nrow(out$specifications), 4)
  expect_equal(nrow(out$results), 4)
  expect_setequal(out$results$.where_precision, c("all", "precise"))
  expect_equal(
    out$results$total[out$results$.scenario == "best" &
                        out$results$.where_precision == "all"],
    9
  )
})

test_that("sensitivity analysis can return transformed data", {
  x <- data.frame(low = 1:2, best = 2:3, high = 3:4)
  out <- ucdp_sensitivity(x, scenarios = c("low", "high"))
  expect_length(out$data, 2)
  expect_equal(out$data[[1]]$.ucdp_fatalities, 1:2)
  expect_equal(out$data[[2]]$.ucdp_fatalities, 3:4)
  expect_equal(attr(out$data[[1]], "ucdp_scenario"), "low")
})

test_that("sensitivity analysis applies fatality missingness policies", {
  x <- data.frame(
    id = 1:2, low = c(1, NA), best = c(2, NA), high = c(3, NA)
  )
  removed <- ucdp_sensitivity(
    x, scenarios = "best", fatality_missing = "remove"
  )
  expect_equal(nrow(removed$data[[1]]), 1)
  expect_error(
    ucdp_sensitivity(x, scenarios = "best", fatality_missing = "error"),
    "Missing fatality"
  )
  expect_error(
    ucdp_sensitivity(
      x[2, ], scenarios = "best", fatality_missing = "remove"
    ),
    "No observations remain"
  )
})

test_that("sensitivity analysis records or raises analysis errors", {
  x <- data.frame(low = 1, best = 2, high = 3)
  failing <- function(data) stop("deliberate failure")
  recorded <- ucdp_sensitivity(
    x, scenarios = "best", analysis = failing, error = "record"
  )
  expect_equal(recorded$specifications$status, "error")
  expect_match(recorded$specifications$error, "deliberate")
  expect_error(
    ucdp_sensitivity(x, scenarios = "best", analysis = failing),
    "Sensitivity analysis failed"
  )
})

test_that("scenario comparison calculates absolute and relative changes", {
  x <- data.frame(
    id = 1:2, low = c(1, 0), best = c(2, 0), high = c(4, 1)
  )
  scenarios <- ucdp_scenarios(x)
  out <- ucdp_compare_scenarios(scenarios, by = "id")

  expect_s3_class(out, "ucdp_scenario_comparison")
  high_one <- out$id == 1 & out$fatality_scenario == "high"
  expect_equal(out$difference[high_one], 2)
  expect_equal(out$relative_difference[high_one], 1)
  high_two <- out$id == 2 & out$fatality_scenario == "high"
  expect_true(is.na(out$relative_difference[high_two]))
})

test_that("scenario comparison accepts sensitivity results", {
  x <- data.frame(low = 1:2, best = 2:3, high = 3:4)
  sensitivity <- ucdp_sensitivity(
    x,
    analysis = function(data) c(total = sum(data$.ucdp_fatalities))
  )
  out <- ucdp_compare_scenarios(sensitivity)
  expect_equal(nrow(out), 3)
  expect_equal(out$difference[out$.scenario == "low"], -2)
  expect_equal(out$difference[out$.scenario == "high"], 2)
})

test_that("scenario comparison validates keys and values", {
  x <- data.frame(
    fatality_scenario = c("best", "best"), fatalities = c(1, 2)
  )
  expect_error(ucdp_compare_scenarios(x), "duplicated")
  expect_error(
    ucdp_compare_scenarios(
      data.frame(fatality_scenario = "low", fatalities = 1)
    ),
    "not present"
  )
})

test_that("uncertainUCDP adapter maps violence types", {
  x <- data.frame(
    id = 1:4, best = c(2, 5, 1, 3),
    type_of_violence = c(1, "non-state", "os", "any")
  )
  attr(x, "ucdp_source") <- list(ucdp_version = "25.1")
  out <- ucdp_to_uncertainUCDP(x, check_package = FALSE)

  expect_s3_class(out, "ucdp_uncertainUCDP")
  expect_equal(out$.ucdp_fatalities, c(2, 5, 1, 3))
  expect_equal(out$.ucdp_tov, c("sb", "ns", "os", "any"))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "25.1")
  expect_equal(
    attr(out, "ucdp_uncertainUCDP_mapping")$target_version,
    ">= 0.7.6"
  )
})

test_that("uncertainUCDP adapter validates and handles missing inputs", {
  x <- data.frame(best = c(2, NA), type_of_violence = c(1, NA))
  expect_error(
    ucdp_to_uncertainUCDP(x, check_package = FALSE),
    "Missing uncertainUCDP inputs"
  )
  kept <- ucdp_to_uncertainUCDP(
    x, missing = "keep", check_package = FALSE
  )
  dropped <- ucdp_to_uncertainUCDP(
    x, missing = "drop", check_package = FALSE
  )
  expect_equal(nrow(kept), 2)
  expect_equal(nrow(dropped), 1)
  expect_error(
    ucdp_to_uncertainUCDP(
      data.frame(best = 1, type_of_violence = "unknown"),
      check_package = FALSE
    ),
    "Unsupported type"
  )
})

test_that("uncertainUCDP adapter supports explicit columns", {
  x <- data.frame(fatal = 3, violence = "state based")
  out <- ucdp_to_uncertainUCDP(
    x, fatalities = "fatal", type_of_violence = "violence",
    check_package = FALSE
  )
  expect_equal(out$.ucdp_fatalities, 3)
  expect_equal(out$.ucdp_tov, "sb")
  expect_error(
    ucdp_to_uncertainUCDP(
      data.frame(best = 1.5, type_of_violence = 1),
      check_package = FALSE
    ),
    "non-negative integer"
  )
  expect_error(
    ucdp_to_uncertainUCDP(
      data.frame(best = 1, type_of_conflict = 3),
      check_package = FALSE
    ),
    "identify.*type_of_violence"
  )
})
