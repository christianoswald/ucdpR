test_that("live UCDP catalog remains discoverable", {
  skip_on_cran()
  skip_if_offline(host = "ucdp.uu.se")
  x <- ucdp_catalog(quiet = TRUE)
  expect_s3_class(x, "tbl_df")
  expect_gt(nrow(x), 10)
  expect_true(any(grepl("Georeferenced", x$dataset)))
  expect_true(any(grepl("/ged/", x$url, fixed = TRUE)))
  expected_datasets <- c(
    "UCDP One-sided Violence Dataset",
    "UCDP Non-State Conflict Dataset",
    "UCDP Violent Political Protest Dataset",
    "UCDP Conflict Termination Dataset",
    "UCDP Peace Agreement Dataset"
  )
  expect_true(all(expected_datasets %in% x$dataset))
  expected_sections <- c(
    "Disaggregated Event Datasets",
    "Yearly Datasets covering 1946\u20132025",
    "Yearly Datasets covering 1989\u20132025",
    "Other UCDP Datasets"
  )
  expect_true(all(expected_sections %in% x$section))
  expect_true(all(grepl("^https://", x$url)))
})

test_that("live catalog exposes official codebooks", {
  skip_on_cran()
  skip_if_offline(host = "ucdp.uu.se")
  x <- ucdp_catalog(include_documentation = TRUE, quiet = TRUE)
  docs <- x[x$format == "documentation", , drop = FALSE]
  expect_gt(nrow(docs), 5)
  expect_true(any(grepl("Georeferenced", docs$dataset)))
  expect_true(all(grepl("^https://", docs$url)))
})

