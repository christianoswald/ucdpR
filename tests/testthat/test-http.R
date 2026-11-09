test_that("citation request failures are informative", {
  skip_if_not_installed("httptest2")

  httptest2::without_internet({
    expect_error(
      ucdp_cite("ged", quiet = TRUE),
      "Could not retrieve UCDP citation guidance"
    )
  })
})

test_that("dataset download failures are informative and leave no file", {
  skip_if_not_installed("httptest2")
  destination <- withr::local_tempdir()

  httptest2::without_internet({
    expect_error(
      ucdp_download(
        "ged", version = "26.1", format = "csv", catalog = fixture_catalog(),
        dest_dir = destination, quiet = TRUE
      ),
      "UCDP file could not be downloaded"
    )
  })
  expect_length(list.files(destination, all.files = TRUE, no.. = TRUE), 0L)
})

test_that("codebook download failures are informative and leave no file", {
  skip_if_not_installed("httptest2")
  destination <- withr::local_tempdir()
  catalog <- tibble::tibble(
    dataset = "UCDP Georeferenced Event Dataset (GED)",
    version = "26.1",
    variant = NA_character_,
    section = "Disaggregated Event Datasets",
    format = "documentation",
    url = "https://ucdp.uu.se/downloads/ged/ged261-codebook.pdf",
    file_name = "ged261-codebook.pdf",
    source = "current"
  )

  httptest2::without_internet({
    expect_error(
      ucdp_codebook(
        "ged", version = "26.1", catalog = catalog,
        dest_dir = destination, quiet = TRUE
      ),
      "UCDP codebook could not be downloaded"
    )
  })
  expect_length(list.files(destination, all.files = TRUE, no.. = TRUE), 0L)
})

test_that("replication download failures are informative and leave no file", {
  skip_if_not_installed("httptest2")
  destination <- withr::local_tempdir()
  catalog <- tibble::tibble(
    year = 2025L,
    publication = "Example publication",
    dataset = "UCDP Georeferenced Event Dataset (GED)",
    version = "25.1",
    file_type = "data",
    title = "GED 25.1 replication data",
    format = "csv",
    url = "https://ucdp.uu.se/downloads/replication_data/ged251.csv",
    file_name = "ged251.csv"
  )

  httptest2::without_internet({
    expect_error(
      ucdp_replication_download(
        "ged", version = "25.1", catalog = catalog,
        dest_dir = destination, quiet = TRUE
      ),
      "UCDP archive file could not be downloaded"
    )
  })
  expect_length(list.files(destination, all.files = TRUE, no.. = TRUE), 0L)
})
