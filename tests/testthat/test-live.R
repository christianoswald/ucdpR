test_that("live UCDP catalog remains discoverable", {
  skip_on_cran()
  skip_if_offline(host = "ucdp.uu.se")
  x <- ucdp_catalog(quiet = TRUE)
  expect_s3_class(x, "tbl_df")
  expect_gt(nrow(x), 10)
  expect_true(any(grepl("Georeferenced", x$dataset)))
  expect_true(any(grepl("/ged/", x$url, fixed = TRUE)))
  expect_true(all(grepl("^https://", x$url)))
})

