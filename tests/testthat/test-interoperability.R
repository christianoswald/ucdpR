test_that("country crosswalk adds year-specific counterpart codes", {
  x <- data.frame(country_id = c(2, 20, 2), year = c(2020, 2020, 2021))
  attr(x, "ucdp_source") <- list(ucdp_version = "26.1")
  map <- data.frame(year = c(2020, 2020, 2021), gwcode = c(2, 20, 2),
                    ccode = c(2, 20, 200))
  out <- ucdp_country_crosswalk(x, crosswalk = map)
  expect_equal(out$ccode, c(2L, 20L, 200L))
  expect_equal(attr(out, "ucdp_source")$ucdp_version, "26.1")
  expect_equal(attr(out, "ucdp_crosswalk")$unmatched, 0)
  expect_equal(attr(out, "ucdp_crosswalk")$source, "supplied")
})

test_that("country crosswalk handles unmatched rows explicitly", {
  x <- data.frame(country_id = c(2, 999), year = 2020)
  map <- data.frame(year = 2020, gwcode = 2, ccode = 2)
  kept <- ucdp_country_crosswalk(x, crosswalk = map)
  expect_equal(kept$ccode, c(2L, NA_integer_))
  expect_warning(ucdp_country_crosswalk(x, crosswalk = map, unmatched = "warn"), "1 row")
  expect_equal(nrow(ucdp_country_crosswalk(x, crosswalk = map, unmatched = "drop")), 1)
  expect_error(ucdp_country_crosswalk(x, crosswalk = map, unmatched = "error"), "1 row")
})

test_that("country crosswalk validates inputs", {
  x <- data.frame(country_id = 2, year = 2020)
  expect_error(ucdp_country_crosswalk(x, crosswalk = data.frame(year = 2020)), "lacks")
  duplicate <- data.frame(year = c(2020, 2020), gwcode = c(2, 2), ccode = c(2, 3))
  expect_error(ucdp_country_crosswalk(x, crosswalk = duplicate), "duplicate")
  expect_error(ucdp_country_crosswalk(transform(x, country_id = "two"),
                                      crosswalk = duplicate), "non-integer")
})

test_that("PRIO-GRID assignment accepts a frozen raster", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  grid <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2,
                      ymin = 0, ymax = 2, crs = "EPSG:4326")
  terra::values(grid) <- 1:4
  x <- data.frame(id = 1:3, longitude = c(0.5, 1.5, 3), latitude = c(1.5, 0.5, 3))
  out <- ucdp_to_priogrid(x, grid = grid)
  expect_equal(out$pgid, c(1, 4, NA))
  expect_equal(attr(out, "ucdp_priogrid")$unmatched, 1)
  expect_equal(nrow(ucdp_to_priogrid(x, grid = grid, missing = "drop")), 2)
  expect_error(ucdp_to_priogrid(x, grid = grid, missing = "error"), "1 row")
})

test_that("peacesciencer bridge standardizes state-year keys", {
  skip_if_not_installed("peacesciencer")
  x <- data.frame(country_id = c(2, 20), yr = c(2020, 2020), events = c(1, 3))
  out <- ucdp_to_peacesciencer(x, code = "country_id", year = "yr")
  expect_equal(out$gwcode, c(2L, 20L))
  expect_equal(out$year, c(2020L, 2020L))
  expect_equal(attr(out, "ucdp_interoperability")$type, "state-year")
})

test_that("peacesciencer bridge catches duplicate analytical keys", {
  skip_if_not_installed("peacesciencer")
  x <- data.frame(country_id = c(2, 2), year = c(2020, 2020))
  expect_error(ucdp_to_peacesciencer(x), "not unique")
})
