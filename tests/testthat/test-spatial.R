test_that("precision summaries report codes, labels, counts, and shares", {
  x <- data.frame(
    year = c(2020, 2020, 2021, 2021),
    where_prec = c(1, 2, 2, NA),
    date_prec = c(1, 1, 3, 5)
  )
  out <- ucdp_precision(x)

  expect_s3_class(out, "tbl_df")
  expect_named(out, c("dimension", "variable", "code", "label", "n", "share"))
  expect_equal(sum(out$n[out$variable == "where_prec"]), 4)
  expect_equal(sum(out$share[out$variable == "where_prec"]), 1)
  expect_true("Exact location" %in% out$label)
  expect_true("Missing" %in% out$label)
})

test_that("precision summaries support groups", {
  x <- data.frame(
    country = c("A", "A", "B"),
    where_prec = c(1, 2, 1)
  )
  out <- ucdp_precision(x, by = "country")

  expect_true("country" %in% names(out))
  expect_equal(sum(out$n[out$country == "A"]), 2)
  expect_equal(sum(out$n[out$country == "B"]), 1)
  expect_equal(sum(out$share[out$country == "A"]), 1)
})

test_that("precision summaries validate their inputs", {
  expect_error(ucdp_precision(data.frame(x = 1)), "neither")
  expect_error(
    ucdp_precision(data.frame(where_prec = 1), by = "country"),
    "not found"
  )
  expect_error(
    ucdp_precision(data.frame(where_prec = "exact")),
    "non-integer"
  )
})

test_that("precision filtering combines spatial and temporal criteria", {
  x <- data.frame(
    id = 1:5,
    where_prec = c(1, 2, 3, NA, 1),
    date_prec = c(1, 3, 1, 1, NA)
  )
  attr(x, "ucdp_source") <- list(ucdp_version = "26.1")

  out <- ucdp_filter_precision(x, where_prec = 1:2, date_prec = 1:3)
  expect_equal(out$id, c(1, 2))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "26.1")

  kept <- ucdp_filter_precision(x, where_prec = 1, missing = "keep")
  expect_equal(kept$id, c(1, 4, 5))
  expect_error(
    ucdp_filter_precision(x, date_prec = 1, missing = "error"),
    "Missing values"
  )
})

test_that("precision filtering validates requested columns and codes", {
  expect_error(
    ucdp_filter_precision(data.frame(x = 1), where_prec = 1),
    "not found"
  )
  expect_error(
    ucdp_filter_precision(data.frame(where_prec = 1), where_prec = NA),
    "non-missing numeric"
  )
})

test_that("ucdp_as_sf creates point geometry and preserves provenance", {
  skip_if_not_installed("sf")
  x <- data.frame(id = 1:2, longitude = c(10, 20), latitude = c(50, 60))
  attr(x, "ucdp_source") <- list(ucdp_version = "26.1")

  out <- ucdp_as_sf(x)
  expect_s3_class(out, "sf")
  expect_equal(sf::st_crs(out)$epsg, 4326)
  expect_equal(unname(sf::st_coordinates(out)[, 1]), c(10, 20))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "26.1")
  expect_equal(attr(out, "ucdp_coordinates"),
               c(longitude = "longitude", latitude = "latitude"))
})

test_that("ucdp_as_sf handles missing and invalid coordinates explicitly", {
  skip_if_not_installed("sf")
  x <- data.frame(longitude = c(10, NA), latitude = c(50, 60))
  expect_equal(nrow(ucdp_as_sf(x, missing = "drop")), 1)
  expect_error(ucdp_as_sf(x, missing = "error"), "Missing coordinates")
  expect_error(
    ucdp_as_sf(data.frame(longitude = 200, latitude = 10)),
    "outside the valid range"
  )
  expect_error(
    ucdp_as_sf(data.frame(longitude = "east", latitude = 10)),
    "non-numeric"
  )
})

test_that("ucdp_as_sf supports explicit alternative coordinate names", {
  skip_if_not_installed("sf")
  x <- data.frame(x_coord = 10, y_coord = 50)
  out <- ucdp_as_sf(x, longitude = "x_coord", latitude = "y_coord")
  expect_s3_class(out, "sf")
})
