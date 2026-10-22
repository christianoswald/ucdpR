test_that("version comparison classifies row and cell changes", {
  old <- data.frame(
    id = 1:3, deaths = c(1, 2, 3), label = c("a", "b", "c"),
    version = "1.0"
  )
  new <- data.frame(
    id = 2:4, deaths = c(2, 4, 1), label = c("b", "c", "d"),
    version = "2.0"
  )
  out <- ucdp_compare_versions(
    "ged", "1.0", "2.0", key = "id", detail = "cells",
    old_data = old, new_data = new
  )

  expect_s3_class(out, "ucdp_version_comparison")
  expect_equal(out$overview$added, 1)
  expect_equal(out$overview$removed, 1)
  expect_equal(out$overview$modified, 1)
  expect_equal(out$overview$unchanged, 1)
  expect_equal(out$added$id, 4)
  expect_equal(out$removed$id, 1)
  expect_equal(out$modified$id, 3)
  expect_equal(out$modified$changed_columns, "deaths")
  expect_equal(out$cell_changes$old_value, "3")
  expect_equal(out$cell_changes$new_value, "4")
  expect_false("version" %in% out$variables$variable)
})

test_that("keys are inferred and must be unique", {
  old <- data.frame(dyad_id = c(1, 1), year = c(2020, 2021), x = 1:2)
  new <- data.frame(dyad_id = c(1, 1), year = c(2020, 2021), x = c(1, 3))
  out <- ucdp_compare_versions(
    "dyadic", "1", "2", old_data = old, new_data = new
  )
  expect_equal(out$metadata$key, c("dyad_id", "year"))

  duplicated <- rbind(old, old[1, ])
  expect_error(
    ucdp_compare_versions(
      "dyadic", "1", "2", key = c("dyad_id", "year"),
      old_data = duplicated, new_data = new
    ),
    "duplicated"
  )
})

test_that("numeric tolerance and schema changes are reported", {
  old <- data.frame(id = 1, estimate = 1, old_only = "x")
  new <- data.frame(id = 1, estimate = 1 + 1e-12, new_only = "y")
  out <- ucdp_compare_versions(
    "ged", "1", "2", key = "id",
    old_data = old, new_data = new
  )
  expect_equal(out$overview$modified, 0)
  expect_equal(out$metadata$columns_added, "new_only")
  expect_equal(out$metadata$columns_removed, "old_only")
})

test_that("summary detail avoids retaining changed rows", {
  old <- data.frame(id = 1, x = 1)
  new <- data.frame(id = 1, x = 2)
  out <- ucdp_compare_versions(
    "ged", "1", "2", key = "id", detail = "summary",
    old_data = old, new_data = new
  )
  expect_null(out$added)
  expect_null(out$removed)
  expect_null(out$modified)
  expect_null(out$cell_changes)
  expect_equal(out$variables$n_changed, 1)
})

test_that("both preloaded releases are required", {
  expect_error(
    ucdp_compare_versions(
      "ged", "1", "2", old_data = data.frame(id = 1)
    ),
    "both"
  )
})

