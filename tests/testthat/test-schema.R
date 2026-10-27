test_that("schema describes classes, missingness, ranges, and examples", {
  x <- data.frame(
    id = 1:3,
    year = c(2020, NA, 2022),
    country = c("A", "A", "B"),
    stringsAsFactors = FALSE
  )
  out <- ucdp_schema(x)

  expect_s3_class(out, "tbl_df")
  expect_named(out, c(
    "variable", "class", "storage_type", "n_missing", "pct_missing",
    "n_unique", "minimum", "maximum", "examples"
  ))
  expect_equal(out$n_missing[out$variable == "year"], 1)
  expect_equal(out$minimum[out$variable == "year"], "2020")
  expect_equal(out$maximum[out$variable == "year"], "2022")
  expect_equal(out$n_unique[out$variable == "country"], 2)
  expect_s3_class(attr(out, "ucdp_metadata"), "tbl_df")
})

test_that("schema retains source metadata", {
  x <- data.frame(id = 1:2)
  attr(x, "ucdp_source") <- list(
    ucdp_record = fixture_catalog()[1, ], ucdp_version = "26.1"
  )
  out <- ucdp_schema(x)
  expect_equal(attr(out, "ucdp_metadata")$version, "26.1")
})

test_that("schema rejects unsupported inputs", {
  expect_error(ucdp_schema(1:3), "data frame or dataset name")
  expect_error(ucdp_schema(c("ged", "prio")), "one dataset name")
})
