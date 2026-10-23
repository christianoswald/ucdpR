test_that("metadata summarizes ordinary data frames", {
  x <- data.frame(
    year = c(2020, 2022),
    date_start = c("2020-01-02", "2022-12-30"),
    latitude = c(-10, 20),
    longitude = c(30, 40)
  )
  out <- ucdp_metadata(x, dataset = "Example")

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1)
  expect_equal(out$dataset, "Example")
  expect_equal(out$n_rows, 2)
  expect_equal(out$n_columns, 4)
  expect_equal(out$year_min, 2020)
  expect_equal(out$year_max, 2022)
  expect_equal(out$date_min, "2020-01-02")
  expect_equal(out$date_max, "2022-12-30")
  expect_equal(out$latitude_min, -10)
  expect_equal(out$longitude_max, 40)
})

test_that("metadata recovers provenance attached by ucdp_get", {
  x <- data.frame(id = 1:2, year = 2020:2021)
  record <- fixture_catalog()[1, ]
  attr(x, "ucdp_source") <- list(
    ucdp_record = record,
    ucdp_version = "26.1",
    md5 = "abc123",
    retrieved_at = "2026-10-23 10:00:00 UTC",
    ucdpR_version = "0.4.0"
  )
  out <- ucdp_metadata(x)

  expect_equal(out$dataset, record$dataset)
  expect_equal(out$version, "26.1")
  expect_equal(out$source_url, record$url)
  expect_equal(out$md5, "abc123")
  expect_equal(out$ucdpR_version, "0.4.0")
})

test_that("metadata can describe an exact catalog release", {
  out <- ucdp_metadata(
    "ged", version = "24.1", format = "csv",
    catalog = fixture_catalog(), quiet = TRUE
  )
  expect_equal(out$version, "24.1")
  expect_equal(out$catalog_source, "historical")
  expect_true(is.na(out$n_rows))
})

test_that("metadata rejects character vectors that are not scalar", {
  expect_error(ucdp_metadata(c("ged", "prio")), "must be one path")
})
