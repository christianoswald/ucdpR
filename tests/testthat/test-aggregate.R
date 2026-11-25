test_that("fatality summaries detect common columns and preserve bounds", {
  x <- data.frame(
    country = c("A", "A", "B"),
    low = c(1, 2, NA), best = c(2, 3, 4), high = c(3, 5, 6)
  )
  attr(x, "ucdp_source") <- list(ucdp_version = "25.1")
  out <- ucdp_fatalities(x, by = "country")

  expect_s3_class(out, "tbl_df")
  expect_named(out, c(
    "country", "n_observations", "n_complete", "n_missing",
    "fatalities_low", "fatalities_best", "fatalities_high"
  ))
  expect_equal(out$fatalities_best, c(5, 4))
  expect_equal(out$fatalities_low, c(3, NA))
  expect_equal(out$n_missing, c(0, 1))
  expect_equal(attr(out, "ucdp_fatality_columns"),
               c(low = "low", best = "best", high = "high"))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "25.1")
})

test_that("fatality summaries support BRD names and explicit columns", {
  brd <- data.frame(
    group = c("A", "A"), bd_low = c(1, 2),
    bd_best = c(2, 3), bd_high = c(3, 4)
  )
  expect_equal(ucdp_fatalities(brd)$fatalities_best, 5)

  custom <- data.frame(lo = 1:2, mid = 2:3, hi = 3:4)
  out <- ucdp_fatalities(custom, low = "lo", best = "mid", high = "hi")
  expect_equal(out$fatalities_high, 7)
})

test_that("fatality summaries expose missing-value behavior", {
  x <- data.frame(low = c(1, NA), best = c(2, 3), high = c(3, 4))
  removed <- ucdp_fatalities(x, na_rm = TRUE)
  retained <- ucdp_fatalities(x, na_rm = FALSE)
  explicit <- ucdp_fatalities(x, fatality_missing = "propagate")

  expect_equal(removed$fatalities_low, 1)
  expect_true(is.na(retained$fatalities_low))
  expect_true(is.na(explicit$fatalities_low))
  expect_equal(removed$n_complete, 1)
  expect_equal(attr(removed, "ucdp_fatality_missing"), "remove")
  expect_equal(attr(explicit, "ucdp_fatality_missing"), "propagate")
  expect_error(
    ucdp_fatalities(x, fatality_missing = "error"),
    "Missing fatality estimates"
  )
})

test_that("all-missing fatality groups remain unknown", {
  x <- data.frame(
    group = c("A", "A"), low = c(NA, NA),
    best = c(NA, NA), high = c(NA, NA)
  )
  out <- ucdp_fatalities(x, by = "group", fatality_missing = "remove")
  expect_true(all(is.na(out[c(
    "fatalities_low", "fatalities_best", "fatalities_high"
  )])))
  expect_equal(out$n_missing, 2)
})

test_that("partial totals report inconsistent aggregated bounds", {
  x <- data.frame(
    low = c(4, 4), best = c(5, NA), high = c(6, 6)
  )
  expect_warning(
    out <- ucdp_fatalities(x, fatality_missing = "remove"),
    "Aggregated fatality bounds are inconsistent"
  )
  expect_equal(out$fatalities_low, 8)
  expect_equal(out$fatalities_best, 5)
  expect_equal(out$n_missing, 1)
})

test_that("fatality summaries validate columns and intervals", {
  expect_error(ucdp_fatalities(data.frame(x = 1)), "Could not identify")
  expect_error(
    ucdp_fatalities(data.frame(low = 1, best = 2, high = 3), low = "low"),
    "Supply all"
  )
  expect_error(
    ucdp_fatalities(data.frame(low = 3, best = 2, high = 4)),
    "inconsistent"
  )
  expect_error(
    ucdp_fatalities(data.frame(low = -1, best = 2, high = 3)),
    "negative"
  )
})

test_that("country-year aggregation counts events and sums fatalities", {
  x <- data.frame(
    country_id = c(1, 1, 1, 2), country = c("A", "A", "A", "B"),
    year = c(2020, 2020, 2021, 2020),
    low = c(0, 1, 2, 1), best = c(1, 2, 3, 2), high = c(2, 3, 4, 3)
  )
  attr(x, "ucdp_source") <- list(ucdp_version = "25.1")
  out <- ucdp_aggregate(x, "country-year")

  expect_s3_class(out, "tbl_df")
  expect_equal(out$n_events, c(2, 1, 1))
  expect_equal(out$fatalities_best, c(3, 3, 2))
  expect_equal(names(out)[1:3], c("country_id", "country", "year"))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "25.1")
  expect_equal(attr(out, "ucdp_aggregation")$unit, "country-year")
})

test_that("monthly aggregation derives time from dates", {
  x <- data.frame(
    conflict_id = c(1, 1, 1),
    date_start = as.Date(c("2020-01-01", "2020-01-20", "2020-03-01"))
  )
  out <- ucdp_aggregate(x, "conflict-month", include_fatalities = FALSE)

  expect_equal(out$year, c(2020, 2020))
  expect_equal(out$month, c(1, 3))
  expect_equal(out$n_events, c(2, 1))
})

test_that("aggregation supports explicit identifiers and extra groups", {
  x <- data.frame(
    my_grid = c(10, 10, 10), type = c(1, 1, 2),
    year = c(2020, 2020, 2020)
  )
  out <- ucdp_aggregate(
    x, "grid-year", id = "my_grid", by = "type",
    include_fatalities = FALSE
  )
  expect_equal(out$n_events, c(2, 1))
  expect_named(out, c("my_grid", "type", "year", "n_events"))
})

test_that("aggregation handles incomplete keys explicitly", {
  x <- data.frame(country_id = c(1, NA), year = c(2020, 2020))
  out <- ucdp_aggregate(x, "country-year", include_fatalities = FALSE)
  expect_equal(nrow(out), 1)
  expect_equal(attr(out, "ucdp_aggregation")$rows_dropped, 1)
  expect_error(
    ucdp_aggregate(
      x, "country-year", include_fatalities = FALSE, missing = "error"
    ),
    "Missing entity"
  )
})

test_that("aggregation detects exact and conflicting duplicate event keys", {
  exact <- data.frame(
    event_id = c(1, 1), country_id = c(1, 1), year = c(2020, 2020)
  )
  expect_error(
    ucdp_aggregate(exact, "country-year", include_fatalities = FALSE),
    "1 key.*2 row"
  )

  conflicting <- data.frame(
    event_id = c(1, 1), country_id = c(1, 1), year = c(2020, 2020),
    note = c("first", "revised")
  )
  expect_error(
    ucdp_aggregate(conflicting, "country-year", include_fatalities = FALSE),
    "conflicting"
  )
})

test_that("duplicate policy is explicit and recorded", {
  x <- data.frame(
    event_id = c(1, 1), country_id = c(1, 1), year = c(2020, 2020),
    note = c("first", "revised")
  )
  expect_warning(
    warned <- ucdp_aggregate(
      x, "country-year", include_fatalities = FALSE, duplicates = "warn"
    ),
    "Duplicate event keys"
  )
  allowed <- ucdp_aggregate(
    x, "country-year", include_fatalities = FALSE, duplicates = "allow"
  )
  expect_equal(warned$n_events, 2)
  expect_equal(allowed$n_events, 2)
  report <- attr(allowed, "ucdp_aggregation")$duplicate_report
  expect_equal(report$duplicate_keys, 1)
  expect_equal(report$conflicting_keys, 1)
})

test_that("compound event keys are supported and entity IDs are not inferred", {
  x <- data.frame(
    source = c("A", "B", "A"), event = c(1, 1, 2),
    country_id = c(1, 1, 1), year = c(2020, 2020, 2021)
  )
  out <- ucdp_aggregate(
    x, "country-year", event_id = c("source", "event"),
    include_fatalities = FALSE
  )
  expect_equal(out$n_events, c(2, 1))

  entity <- data.frame(id = c(1, 1), year = c(2020, 2021))
  expect_no_error(ucdp_aggregate(
    entity, "conflict-year", id = "id", include_fatalities = FALSE
  ))
})

test_that("yearly panels insert labelled zero-filled periods", {
  x <- data.frame(
    country_id = c(1, 1, 2), year = c(2020, 2022, 2021),
    low = c(0, 1, 2), best = c(1, 2, 3), high = c(2, 3, 4)
  )
  out <- ucdp_panel(x, "country-year", start = 2020, end = 2022)

  expect_equal(nrow(out), 6)
  expect_equal(sum(out$.ucdp_observed), 3)
  expect_equal(sum(out$.ucdp_fill == "zero_filled"), 3)
  inserted <- !out$.ucdp_observed
  expect_true(all(out$n_events[inserted] == 0))
  expect_true(all(out$fatalities_best[inserted] == 0))
})

test_that("panels can preserve inserted combinations as missing", {
  x <- data.frame(country_id = c(1, 1), year = c(2020, 2022))
  aggregated <- ucdp_aggregate(x, "country-year", include_fatalities = FALSE)
  out <- ucdp_panel(aggregated, fill = "missing")

  expect_equal(nrow(out), 3)
  expect_true(is.na(out$n_events[out$year == 2021]))
  expect_equal(out$.ucdp_fill[out$year == 2021], "missing")
})

test_that("panel universes can include never-observed entities", {
  x <- data.frame(country_id = 1, year = 2020)
  out <- ucdp_panel(
    x, "country-year", start = 2020, end = 2021,
    universe = c(1, 2), include_fatalities = FALSE
  )
  expect_equal(nrow(out), 4)
  expect_true(all(out$n_events[out$country_id == 2] == 0))
  expect_false(any(out$.ucdp_observed[out$country_id == 2]))
})

test_that("monthly panels accept explicit boundaries", {
  x <- data.frame(
    dyad_id = c(1, 1), year = c(2020, 2020), month = c(1, 3)
  )
  out <- ucdp_panel(
    x, "dyad-month", start = "2020-01", end = "2020-03",
    include_fatalities = FALSE
  )
  expect_equal(out$month, 1:3)
  expect_equal(out$n_events, c(1, 0, 1))
})

test_that("global coverage separates structural zeroes from unavailable periods", {
  x <- data.frame(country_id = c(1, 1), year = c(2020, 2022))
  out <- ucdp_panel(
    x, "country-year", start = 2019, end = 2023,
    coverage = c(2020, 2022), include_fatalities = FALSE
  )
  expect_equal(
    out$.ucdp_fill,
    c("outside_coverage", "observed", "zero_filled", "observed",
      "outside_coverage")
  )
  expect_true(all(is.na(out$n_events[out$year %in% c(2019, 2023)])))
  expect_equal(out$n_events[out$year == 2021], 0)
  expect_equal(out$.ucdp_in_coverage, c(FALSE, TRUE, TRUE, TRUE, FALSE))
})

test_that("entity-specific coverage is respected", {
  x <- data.frame(country_id = c(1, 2), year = c(2020, 2021))
  coverage <- data.frame(
    country_id = c(1, 2),
    coverage_start = c(2020, 2021), coverage_end = c(2021, 2022)
  )
  out <- ucdp_panel(
    x, "country-year", start = 2020, end = 2022,
    coverage = coverage, include_fatalities = FALSE
  )
  one <- out[out$country_id == 1, ]
  two <- out[out$country_id == 2, ]
  expect_equal(one$.ucdp_fill, c("observed", "zero_filled", "outside_coverage"))
  expect_equal(two$.ucdp_fill, c("outside_coverage", "observed", "zero_filled"))
})

test_that("monthly coverage preserves Date boundaries", {
  x <- data.frame(
    dyad_id = c(1, 1), year = c(2020, 2020), month = c(2, 4)
  )
  coverage <- data.frame(
    dyad_id = 1,
    coverage_start = as.Date("2020-02-01"),
    coverage_end = as.Date("2020-04-01")
  )
  out <- ucdp_panel(
    x, "dyad-month", start = "2020-01", end = "2020-05",
    coverage = coverage, include_fatalities = FALSE
  )
  expect_equal(
    out$.ucdp_fill,
    c("outside_coverage", "observed", "zero_filled", "observed",
      "outside_coverage")
  )
})

test_that("declared coverage is validated", {
  x <- data.frame(country_id = c(1, 1), year = c(2020, 2022))
  expect_error(
    ucdp_panel(
      x, "country-year", start = 2020, end = 2022,
      coverage = c(2021, 2022), include_fatalities = FALSE
    ),
    "Observed panel rows fall outside"
  )
  expect_error(
    ucdp_panel(
      x, "country-year", coverage = data.frame(country_id = 1),
      include_fatalities = FALSE
    ),
    "missing columns"
  )
  expect_error(
    ucdp_panel(
      x, "country-year", coverage = c(2022, 2020),
      include_fatalities = FALSE
    ),
    "start must not be later"
  )
})

test_that("panel construction validates its specification", {
  x <- data.frame(country_id = 1, year = 2020)
  expect_error(ucdp_panel(x), "unit.*required")
  expect_error(
    ucdp_panel(data.frame(country_id = 1, year = 2020, n_events = 1),
               unit = "country-year"),
    "lack.*specification"
  )
  expect_error(
    ucdp_aggregate(x, "unsupported", include_fatalities = FALSE),
    "Unsupported"
  )
  expect_error(
    ucdp_panel(
      x, "country-year", start = 2021, end = 2020,
      include_fatalities = FALSE
    ),
    "must not be later"
  )
})
