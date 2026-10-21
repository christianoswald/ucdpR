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

