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

