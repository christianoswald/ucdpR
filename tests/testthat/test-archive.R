replication_html <- function() {
  xml2::read_html(paste0(
    "<html><body>",
    "<h2>2025</h2>",
    "<p>Author A (2025). Annual article.</p>",
    "<p><a href='/downloads/replication_data/ged251.csv'>",
    "UCDP Georeferenced Event Dataset v. 25.1</a> ",
    "<a href='/downloads/replication_data/ged251.pdf'>",
    "Codebook for the UCDP Georeferenced Event Dataset v. 25.1</a></p>",
    "<h2>2024</h2>",
    "<p>Author B (2024). Earlier article.</p>",
    "<p><a href='/downloads/replication_data/ucdp-prio-acd-241.csv'>",
    "UCDP/PRIO Armed Conflict Dataset v. 24.1, 1946-2023</a> ",
    "<a href='/downloads/replication_data/ucdp-prio-history-241.pdf'>",
    "Version History v. 24.1</a></p>",
    "</body></html>"
  ))
}

fixture_replication_catalog <- function() {
  ucdpR:::parse_replication_html(
    replication_html(), "https://ucdp.uu.se/downloads/replication_data.html"
  )
}

test_that("replication HTML is parsed into a stable catalog", {
  out <- fixture_replication_catalog()
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 4)
  expect_named(out, c(
    "year", "publication", "dataset", "version", "file_type", "title",
    "format", "url", "file_name"
  ))
  expect_equal(out$publication[out$year == 2025][[1]],
               "Author A (2025). Annual article.")
  expect_true(any(out$file_type == "codebook"))
  expect_true(any(out$file_type == "version_history"))
  expect_true(all(grepl("^https://", out$url)))
})

test_that("replication catalogs can be filtered", {
  x <- fixture_replication_catalog()
  out <- ucdpR:::filter_replication_catalog(
    x, query = "Georeferenced", year = 2025, type = "data"
  )
  expect_equal(nrow(out), 1)
  expect_equal(out$version, "25.1")
})

test_that("replication downloads reject ambiguous and missing selections", {
  x <- fixture_replication_catalog()
  expect_error(
    ucdp_replication_download(
      "ged", type = c("data", "codebook"), catalog = x, quiet = TRUE
    ),
    "more than one"
  )
  expect_error(
    ucdp_replication_download("dyadic", catalog = x, quiet = TRUE),
    "No matching"
  )
})

test_that("version-history HTML is parsed independently", {
  page <- xml2::read_html(paste0(
    "<html><body><h2>Yearly Datasets</h2>",
    "<h3>UCDP/PRIO Armed Conflict Dataset version 26.1</h3>",
    "<p><a href='/downloads/ucdpprio/history-261.pdf'>Version history</a></p>",
    "</body></html>"
  ))
  out <- ucdpR:::parse_version_history_html(
    page, "https://ucdp.uu.se/downloads/", "current"
  )
  expect_equal(nrow(out), 1)
  expect_equal(out$dataset, "UCDP/PRIO Armed Conflict Dataset")
  expect_equal(out$version, "26.1")
  expect_equal(out$file_type, "version_history")
})

test_that("version-history requests validate ambiguity before downloading", {
  one <- tibble::tibble(
    dataset = "UCDP/PRIO Armed Conflict Dataset",
    version = c("25.1", "24.1"),
    file_type = "version_history",
    title = "Version history",
    format = "pdf",
    url = c("https://ucdp.uu.se/a.pdf", "https://ucdp.uu.se/b.pdf"),
    file_name = c("a.pdf", "b.pdf"),
    source = "historical"
  )
  expect_error(
    ucdp_version_history("prio", catalog = one, quiet = TRUE),
    "more than one"
  )
  expect_error(ucdp_version_history("prio", open = NA), "TRUE or FALSE")
})
