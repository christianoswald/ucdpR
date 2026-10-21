fixture_catalog <- function() {
  tibble::tibble(
    dataset = c("UCDP Georeferenced Event Dataset (GED) Global", "UCDP Georeferenced Event Dataset (GED)", "UCDP Battle Related Deaths Dataset", "UCDP Battle Related Deaths Dataset"),
    version = c("26.1", "24.1", "26.1", "26.1"),
    variant = c(NA, NA, "dyadic level", "conflict level"),
    section = c("Disaggregated Event Datasets", "UCDP Georeferenced Event Dataset (GED)", "Yearly Datasets", "Yearly Datasets"),
    format = c("csv", "csv", "csv", "csv"),
    url = c("https://ucdp.uu.se/downloads/ged/ged261-csv.zip", "https://ucdp.uu.se/downloads/ged/ged241-csv.zip", "https://ucdp.uu.se/a.csv", "https://ucdp.uu.se/b.csv"),
    file_name = c("ged261-csv.zip", "ged241-csv.zip", "a.csv", "b.csv"),
    source = c("current", "historical", "current", "current")
  )
}

