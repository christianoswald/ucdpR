test_that("catalog helper has stable empty schema", {
  x <- ucdpR:::empty_catalog()
  expect_s3_class(x, "tbl_df")
  expect_named(x, c("dataset", "version", "variant", "section", "format", "url", "file_name", "source"))
})

test_that("catalog validation flag must be scalar and non-missing", {
  expect_error(ucdp_catalog(validate = NA), "is not TRUE")
  expect_error(ucdp_catalog(validate = c(TRUE, FALSE)), "length")
})

test_that("format inference handles supported types", {
  expect_equal(ucdpR:::infer_format("CSV", "file"), "csv")
  expect_equal(ucdpR:::infer_format("Excel", "file"), "xlsx")
  expect_equal(ucdpR:::infer_format("Stata", "file"), "dta")
  expect_equal(ucdpR:::infer_format("R", "file"), "rdata")
  expect_equal(ucdpR:::infer_format("SHAPEFILE", "file"), "shapefile")
  expect_equal(ucdpR:::infer_format("Codebook", "file.pdf"), "documentation")
})

test_that("versions and names are normalized", {
  expect_equal(ucdpR:::extract_version("Dataset version 26.1"), "26.1")
  expect_equal(ucdpR:::safe_name("One-sided Violence"), "one-sided-violence")
})

test_that("dataset names are recovered from stable download paths", {
  expect_equal(
    ucdpR:::canonical_dataset("Disaggregated Event Datasets", "https://ucdp.uu.se/downloads/ged/ged261.csv"),
    "UCDP Georeferenced Event Dataset (GED)"
  )
  expect_equal(
    ucdpR:::canonical_dataset("Disaggregated Event Datasets", "https://ucdp.uu.se/downloads/candidateged/file.csv"),
    "UCDP Candidate Events Dataset (UCDP Candidate)"
  )
})

test_that("node text retains letters hidden by page display rules", {
  page <- xml2::read_html(paste0(
    "<style>n, r, t { display: none; }</style>",
    "<h2>Yea<r>r</r>ly Da<t>t</t>ase<t>t</t>s</h2>"
  ))
  heading <- xml2::xml_find_first(page, ".//h2")
  expect_equal(ucdpR:::node_text(heading), "Yearly Datasets")
})

test_that("specific auxiliary dataset titles are not overwritten", {
  title <- "UCDP Non-state Conflict Issues and Actors Dataset"
  url <- "https://ucdp.uu.se/downloads/nonstate/issues-and-actors.csv"
  expect_equal(ucdpR:::canonical_dataset(title, url), title)
})

test_that("catalog validation accepts a structurally complete fixture", {
  page <- xml2::read_html(testthat::test_path(
    "fixtures", "catalog-complete.html"
  ))
  out <- ucdpR:::parse_catalog_html(
    page, "https://ucdp.uu.se/downloads/", "current"
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 6)
  expect_true(all(grepl("^https://", out$url)))
  expect_true(all(out$source == "current"))
})

test_that("catalog validation detects incomplete discovery", {
  page <- xml2::read_html(testthat::test_path(
    "fixtures", "catalog-partial.html"
  ))
  expect_warning(
    out <- ucdpR:::parse_catalog_html(
      page, "https://ucdp.uu.se/downloads/", "current"
    ),
    "unexpectedly small"
  )
  expect_equal(nrow(out), 2)
})

test_that("empty and malformed catalog fixtures fail informatively", {
  empty <- xml2::read_html(testthat::test_path(
    "fixtures", "catalog-empty.html"
  ))
  malformed <- xml2::read_html(testthat::test_path(
    "fixtures", "catalog-malformed.html"
  ))
  expect_error(
    ucdpR:::parse_catalog_html(
      empty, "https://ucdp.uu.se/downloads/", "current"
    ),
    "did not contain any usable downloads"
  )
  expect_error(
    ucdpR:::parse_catalog_html(
      malformed, "https://ucdp.uu.se/downloads/", "current"
    ),
    "did not contain any usable downloads"
  )
})

test_that("catalog validation can be bypassed for troubleshooting", {
  page <- xml2::read_html(testthat::test_path(
    "fixtures", "catalog-empty.html"
  ))
  out <- ucdpR:::parse_catalog_html(
    page, "https://ucdp.uu.se/downloads/", "current", validate = FALSE
  )
  expect_equal(nrow(out), 0)
  expect_named(out, names(ucdpR:::empty_catalog()))
})

test_that("catalog validation rejects malformed rows and schemas", {
  expect_error(
    ucdpR:::validate_catalog_result(
      data.frame(dataset = "GED"), "current",
      "https://ucdp.uu.se/downloads/"
    ),
    "Missing columns"
  )
  bad <- ucdpR:::empty_catalog()
  bad[1, ] <- list(
    "GED", "26.1", NA_character_, "Events", "csv", "not-a-url",
    "ged.csv", "current"
  )
  expect_error(
    ucdpR:::validate_catalog_result(
      bad, "current", "https://ucdp.uu.se/downloads/", minimum = 1
    ),
    "malformed rows"
  )
})

