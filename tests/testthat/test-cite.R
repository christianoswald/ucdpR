test_that("citation guidance is extracted from the dataset section", {
  page <- xml2::read_html(paste0(
    "<h2>UCDP Georeferenced Event Dataset (GED)</h2>",
    "<p>Downloads</p>",
    "<p>Please cite the UCDP GED codebook.</p>",
    "<p>Dataset version 26.1.</p>",
    "<h2>Another dataset</h2>"
  ))

  out <- ucdpR:::extract_ucdp_citation(page, "ged")
  expect_equal(
    out,
    c("Please cite the UCDP GED codebook.", "Dataset version 26.1.")
  )
})

test_that("missing citation guidance fails informatively", {
  page <- xml2::read_html(paste0(
    "<h2>UCDP Georeferenced Event Dataset (GED)</h2>",
    "<p>Downloads only</p>",
    "<h2>Another dataset</h2>"
  ))

  expect_error(
    ucdpR:::extract_ucdp_citation(page, "ged"),
    "Citation guidance could not be extracted"
  )
})

test_that("missing citation dataset fails separately", {
  page <- xml2::read_html("<h2>Another dataset</h2>")
  expect_error(
    ucdpR:::extract_ucdp_citation(page, "ged"),
    "No dataset matching"
  )
})
