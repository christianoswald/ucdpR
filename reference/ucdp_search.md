# Search the UCDP catalog

Search the UCDP catalog

## Usage

``` r
ucdp_search(query, catalog = NULL, ...)
```

## Arguments

- query:

  A case-insensitive regular expression matched against dataset,
  variant, version, and section names.

- catalog:

  A catalog returned by
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md).
  If omitted, the current catalog is downloaded.

- ...:

  Passed to
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md)
  when `catalog` is omitted.

## Value

A filtered catalog tibble.

## Examples

``` r
catalog <- tibble::tibble(
  dataset = c("UCDP Georeferenced Event Dataset (GED)",
              "UCDP/PRIO Armed Conflict Dataset"),
  version = c("25.1", "25.1"), variant = NA_character_,
  section = c("Disaggregated Event Datasets", "Yearly Datasets"),
  format = "csv", url = "https://example.org/data.csv",
  file_name = "data.csv", source = "current"
)
ucdp_search("Georeferenced|GED", catalog)
#> # A tibble: 1 × 8
#>   dataset                  version variant section format url   file_name source
#>   <chr>                    <chr>   <chr>   <chr>   <chr>  <chr> <chr>     <chr> 
#> 1 UCDP Georeferenced Even… 25.1    NA      Disagg… csv    http… data.csv  curre…
if (FALSE) ucdp_search("Georeferenced|GED") # \dontrun{}
```
