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

  expect_equal(removed$fatalities_low, 1)
  expect_true(is.na(retained$fatalities_low))
  expect_equal(removed$n_complete, 1)
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
