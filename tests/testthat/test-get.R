test_that("CSV import adapts when ID lists occur after the guessing sample", {
  skip_if_not_installed("readr")
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  values <- c(as.character(seq_len(1100)), "156, 28, 3")
  writeLines(c("side_a_id", paste0('"', values, '"')), path)

  expect_no_warning(out <- ucdpR:::read_ucdp_csv(path))
  expect_type(out$side_a_id, "character")
  expect_equal(out$side_a_id[[1101]], "156, 28, 3")
  expect_equal(nrow(readr::problems(out)), 0)
})

test_that("explicit readr type controls are respected", {
  skip_if_not_installed("readr")
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("id", "1", "2"), path)

  out <- ucdpR:::read_ucdp_csv(
    path,
    col_types = readr::cols(id = readr::col_character())
  )
  expect_type(out$id, "character")
})

test_that("archive member validation rejects unsafe extraction paths", {
  expect_invisible(ucdpR:::validate_archive_members(c(
    "data/events.csv", "documentation/codebook.pdf"
  )))

  unsafe <- c(
    "../events.csv",
    "data/../../events.csv",
    "/absolute/events.csv",
    "C:\\absolute\\events.csv"
  )
  for (member in unsafe) {
    expect_error(
      ucdpR:::validate_archive_members(member),
      "unsafe file paths"
    )
  }
})
