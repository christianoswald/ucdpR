test_that("search is case insensitive", {
  x <- ucdp_search("georeferenced", fixture_catalog())
  expect_equal(nrow(x), 2)
  expect_match(x$dataset, "GED", fixed = TRUE)
})

test_that("aliases resolve", {
  expect_equal(ucdpR:::resolve_alias("ged"), "Georeferenced Event Dataset")
  expect_equal(ucdpR:::resolve_alias("BRD"), "Battle[- ]Related Deaths")
})

test_that("ambiguous choices fail informatively", {
  x <- fixture_catalog()[3:4, ]
  expect_error(ucdpR:::select_one(x, "brd", "csv", NULL, NULL), "more than one")
  expect_equal(ucdpR:::select_one(x[1, ], "brd", "csv", "dyadic", NULL)$variant, "dyadic level")
})

test_that("historical versions can be listed and selected exactly", {
  x <- ucdp_versions("ged", format = "csv", catalog = fixture_catalog())
  expect_equal(x$version, c("26.1", "24.1"))
  selected <- x[x$version == "24.1", ]
  expect_equal(nrow(selected), 1)
  expect_equal(selected$source, "historical")
})

test_that("Candidate-style version identifiers are extracted", {
  expect_equal(ucdpR:::extract_version("25.0.12 CSV version 25.0.X"), "25.0.12")
  expect_equal(ucdpR:::extract_version("25.01.25.12 CSV"), "25.01.25.12")
})

test_that("update checks do not depend on catalog row order", {
  catalog <- tibble::tibble(
    dataset = "UCDP Georeferenced Event Dataset (GED)",
    version = c("24.1", "26.1", "25.1"),
    variant = NA_character_,
    section = "Disaggregated Event Datasets",
    format = "csv",
    url = paste0("https://example.org/ged", c("241", "261", "251"), ".csv"),
    file_name = paste0("ged", c("241", "261", "251"), ".csv"),
    source = c("historical", "current", "historical")
  )

  out <- ucdp_update_available("ged", "v25.1", catalog = catalog)
  expect_equal(out$current_version, "26.1")
  expect_true(out$update_available)

  current <- ucdp_update_available("ged", "v26.1", catalog = catalog)
  expect_false(current$update_available)
})

test_that("update checks can select formats and variants", {
  catalog <- tibble::tibble(
    dataset = "UCDP Battle Related Deaths Dataset",
    version = c("26.1", "25.1", "26.0"),
    variant = c("dyadic level", "dyadic level", "conflict level"),
    section = "Yearly Datasets",
    format = c("csv", "xlsx", "csv"),
    url = paste0("https://example.org/brd", 1:3),
    file_name = paste0("brd", 1:3),
    source = "current"
  )

  out <- ucdp_update_available(
    "brd", "25.1", variant = "dyadic", format = "xlsx",
    catalog = catalog
  )
  expect_equal(out$current_version, "25.1")
  expect_false(out$update_available)
})

