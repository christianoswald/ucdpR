.ucdp_base <- "https://ucdp.uu.se/downloads/"
.ucdp_history <- "https://ucdp.uu.se/downloads/olddw.html"

ucdp_user_agent <- function() {
  paste0("ucdpR/", utils::packageVersion("ucdpR"),
         " (https://github.com/christianoswald/ucdpR)")
}

ucdp_request <- function(url) {
  httr2::request(url) |>
    httr2::req_user_agent(ucdp_user_agent()) |>
    httr2::req_retry(max_tries = 3, backoff = ~ 1) |>
    httr2::req_timeout(60)
}

ucdp_timestamp <- function() {
  format(Sys.time(), tz = "UTC", usetz = TRUE)
}

download_to_destination <- function(request, destination, overwrite,
                                    error_message, empty_message) {
  validate_flag(overwrite, "overwrite")
  directory <- dirname(destination)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(directory)) {
    cli::cli_abort("Could not create destination directory: {.path {directory}}.")
  }
  if (file.exists(destination) && !overwrite) {
    cli::cli_abort(c(
      "File already exists: {.path {destination}}",
      "i" = "Set {.arg overwrite = TRUE} to replace it."
    ))
  }

  temporary <- tempfile(
    pattern = paste0(".", basename(destination), "-"),
    tmpdir = directory,
    fileext = ".download"
  )
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  tryCatch(
    httr2::req_perform(request, path = temporary),
    error = function(e) {
      cli::cli_abort(c(error_message, "i" = conditionMessage(e)), parent = e)
    }
  )
  if (!file.exists(temporary) || is.na(file.info(temporary)$size) ||
      file.info(temporary)$size == 0) {
    cli::cli_abort(empty_message)
  }

  backup <- NULL
  if (file.exists(destination)) {
    backup <- tempfile(
      pattern = paste0(".", basename(destination), "-backup-"),
      tmpdir = directory
    )
    if (!file.rename(destination, backup)) {
      cli::cli_abort(
        "Could not prepare the existing file for replacement: {.path {destination}}."
      )
    }
    on.exit({
      if (!is.null(backup) && file.exists(backup) && !file.exists(destination)) {
        file.rename(backup, destination)
      }
    }, add = TRUE)
  }

  if (!file.rename(temporary, destination)) {
    if (!is.null(backup) && file.exists(backup)) file.rename(backup, destination)
    cli::cli_abort("Could not move the completed download to {.path {destination}}.")
  }
  if (!is.null(backup) && file.exists(backup)) unlink(backup)
  normalizePath(destination, winslash = "/", mustWork = TRUE)
}

strict_integer_parse <- function(x) {
  text <- trimws(as.character(x))
  nan <- if (is.numeric(x)) is.nan(x) else rep(FALSE, length(x))
  present <- (!is.na(x) | nan) & nzchar(text)
  number <- suppressWarnings(as.numeric(text))
  minimum <- -.Machine$integer.max - 1
  invalid <- present & (
    !is.finite(number) |
      number != floor(number) |
      number < minimum |
      number > .Machine$integer.max
  )
  value <- suppressWarnings(as.integer(number))
  value[!present | invalid] <- NA_integer_
  list(value = value, invalid = invalid, present = present)
}

strict_integer_value <- function(x, name) {
  parsed <- strict_integer_parse(x)
  if (any(parsed$invalid)) {
    cli::cli_abort(
      "Column {.field {name}} contains non-integer values in rows: {which(parsed$invalid)}."
    )
  }
  parsed$value
}

normalize_version_id <- function(x) {
  sub("^[[:space:]]*[Vv][[:space:]]*", "", trimws(as.character(x)))
}

ucdp_package_version <- function() {
  as.character(utils::packageVersion("ucdpR"))
}

absolute_url <- function(href, base) {
  xml2::url_absolute(href, base)
}

clean_text <- function(x) {
  trimws(gsub("[[:space:]]+", " ", x))
}

infer_format <- function(label, url) {
  z <- tolower(paste(label, url))
  if (grepl("codebook|appendix|fixes", tolower(label))) return("documentation")
  if (grepl("\\.csv($|[?#])|\\bcsv\\b", z)) return("csv")
  if (grepl("\\.xlsx?($|[?#])|\\bexcel\\b", z)) return("xlsx")
  if (grepl("\\.dta($|[?#])|\\bstata\\b", z)) return("dta")
  if (grepl("\\.rds($|[?#])", z)) return("rds")
  if (grepl("\\.rdata($|[?#])|\\.rda($|[?#])", z) || tolower(trimws(label)) == "r") return("rdata")
  if (grepl("\\bsql\\b", z)) return("sql")
  if (grepl("shapefile|\\.shp($|[?#])", z)) return("shapefile")
  if (grepl("geojson|\\.geojson($|[?#])", z)) return("geojson")
  if (grepl("\\bkml\\b|\\.kml($|[?#])", z)) return("kml")
  if (grepl("\\bshx\\b|\\.shx($|[?#])", z)) return("shx")
  if (grepl("\\.zip($|[?#])", z)) return("zip")
  if (grepl("\\.pdf($|[?#])", z)) return("pdf")
  "other"
}

extract_version <- function(x) {
  hit <- regmatches(x, regexpr(
    "(?i)(?<=version )[[:alnum:].-]+|(?<=versions: )[[:alnum:].-]+|(?<=GED )[0-9][[:alnum:].-]*|(?<= v)[0-9][[:alnum:].-]*|[0-9]{2}\\.[0-9]{1,2}(?:\\.[0-9]{1,2}){0,4}",
    x, perl = TRUE
  ))
  if (!length(hit) || !nzchar(hit)) return(NA_character_)
  sub("[.,;:]$", "", hit)
}

safe_name <- function(x) {
  x <- iconv(x, to = "ASCII//TRANSLIT")
  x <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  gsub("(^-+|-+$)", "", x)
}

empty_catalog <- function() {
  tibble::tibble(
    dataset = character(), version = character(), variant = character(),
    section = character(), format = character(), url = character(),
    file_name = character(), source = character()
  )
}

