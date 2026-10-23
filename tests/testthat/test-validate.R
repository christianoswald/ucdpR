test_that("clean UCDP-like data pass applicable validation checks", {
  x <- data.frame(
    id = 1:2,
    year = c(2020, 2021),
    date_start = c("2020-01-01", "2021-02-01"),
    date_end = c("2020-01-02", "2021-02-03"),
    low = c(0, 1), best = c(1, 2), high = c(2, 3),
    latitude = c(10, -20), longitude = c(30, -40),
    type_of_violence = c(1, 3)
  )
  out <- ucdp_validate(x)

  expect_s3_class(out, "ucdp_validation")
  expect_true(out$valid)
  expect_equal(out$key, "id")
  expect_equal(nrow(out$issues), 0)
  expect_true(all(out$summary$status == "pass"))
})

test_that("validation reports keys, dates, fatalities, coordinates, and codes", {
  x <- data.frame(
    id = c(1, 1, NA),
    year = c(2020, 2021, 2022),
    date_start = c("2020-02-02", "not-a-date", "2023-01-01"),
    date_end = c("2020-01-01", "2021-03-01", "2023-01-02"),
    low = c(2, 0, 0), best = c(1, -1, 1), high = c(3, 2, 2),
    latitude = c(91, 0, 0), longitude = c(0, -181, 0),
    type_of_violence = c(1, 4, 2)
  )
  out <- ucdp_validate(x)

  expect_false(out$valid)
  expect_true(all(c("keys", "dates", "fatalities", "coordinates", "codes") %in%
                    out$issues$check))
  expect_true(any(out$issues$severity == "error"))
  expect_true(any(out$issues$severity == "warning"))
  expect_true(any(grepl("duplicated", out$issues$message)))
  expect_true(any(grepl("low <= best <= high", out$issues$message, fixed = TRUE)))
})

test_that("strict validation treats warnings as invalid", {
  x <- data.frame(id = 1, type_of_violence = 9)
  expect_true(ucdp_validate(x, strict = FALSE)$valid)
  expect_false(ucdp_validate(x, strict = TRUE)$valid)
})

test_that("non-applicable checks are marked as skipped", {
  out <- ucdp_validate(data.frame(name = c("a", "b")))
  expect_true(out$valid)
  expect_true(all(out$summary$status == "skipped"))
})

test_that("users can select checks and composite keys", {
  x <- data.frame(conflict_id = c(1, 1), year = c(2020, 2021), low = c(-1, 0))
  out <- ucdp_validate(x, key = c("conflict_id", "year"), checks = "keys")
  expect_true(out$valid)
  expect_equal(out$key, c("conflict_id", "year"))
  expect_equal(out$summary$check, "keys")
})

test_that("validation arguments fail informatively", {
  expect_error(ucdp_validate(1:3), "must be a data frame")
  expect_error(ucdp_validate(data.frame(x = 1), checks = "unknown"), "unsupported")
  expect_error(ucdp_validate(data.frame(x = 1), key = "id"), "Missing columns")
})
