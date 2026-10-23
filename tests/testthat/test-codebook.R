fixture_codebooks <- function() {
  tibble::tibble(
    dataset = c(
      "UCDP Georeferenced Event Dataset (GED)",
      "UCDP Battle Related Deaths Dataset",
      "UCDP Battle Related Deaths Dataset",
      "UCDP Conflict Issues Dataset",
      "UCDP Conflict Issues Dataset"
    ),
    version = c("26.1", "26.1", "26.1", "23.2", "23.2"),
    variant = c(NA, "dyadic level", "conflict level", "CID", "narratives"),
    section = "Documentation",
    format = "documentation",
    url = c(
      "https://ucdp.uu.se/downloads/ged/ged261-codebook.pdf",
      "https://ucdp.uu.se/downloads/brd/brd-codebook.pdf",
      "https://ucdp.uu.se/downloads/brd/brd-codebook.pdf",
      "https://ucdp.uu.se/downloads/cid/cid-codebook.pdf",
      "https://ucdp.uu.se/downloads/cid/narratives-codebook.pdf"
    ),
    file_name = c(
      "ged261-codebook.pdf", "brd-codebook.pdf", "brd-codebook.pdf",
      "cid-codebook.pdf", "narratives-codebook.pdf"
    ),
    source = "current"
  )
}

test_that("shared codebook URLs are deduplicated", {
  x <- fixture_codebooks()[2:3, ]
  out <- ucdpR:::select_codebook_record(x, "brd", NULL, NULL)
  expect_equal(nrow(out), 1)
  expect_equal(out$url, x$url[[1]])
})

test_that("genuinely different codebooks require refinement", {
  x <- fixture_codebooks()[4:5, ]
  expect_error(
    ucdpR:::select_codebook_record(x, "issues", NULL, NULL),
    "more than one codebook"
  )
  selected <- x[grepl("narratives", x$variant), ]
  expect_equal(
    ucdpR:::select_codebook_record(selected, "issues", NULL, "narratives")$variant,
    "narratives"
  )
})

test_that("historical requests never silently substitute a current codebook", {
  x <- fixture_codebooks()[0, ]
  expect_error(
    ucdpR:::select_codebook_record(x, "ged", "24.1", NULL),
    "current codebook was not substituted"
  )
})

test_that("codebook validates the open argument before network access", {
  expect_error(ucdp_codebook("ged", open = NA), "must be TRUE or FALSE")
})
