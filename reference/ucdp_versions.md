# List available releases of a UCDP dataset

List available releases of a UCDP dataset

## Usage

``` r
ucdp_versions(
  dataset,
  format = NULL,
  include_documentation = FALSE,
  quiet = FALSE,
  catalog = NULL
)
```

## Arguments

- dataset:

  Dataset name, alias, or regular expression.

- format:

  Optional format to retain, such as `"csv"` or `"xlsx"`.

- include_documentation:

  Include codebooks and documentation?

- quiet:

  Suppress catalog messages?

- catalog:

  Optional catalog containing historical releases. When omitted,
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md)
  is called with `include_historical = TRUE`.

## Value

A catalog tibble sorted from newer to older releases where possible.

## Examples

``` r
catalog <- tibble::tibble(
  dataset = "UCDP Georeferenced Event Dataset (GED)",
  version = c("25.1", "24.1"), variant = NA_character_,
  section = "Disaggregated Event Datasets", format = "csv",
  url = c("https://example.org/ged-251.csv",
          "https://example.org/ged-241.csv"),
  file_name = c("ged-251.csv", "ged-241.csv"),
  source = c("current", "historical")
)
ucdp_versions("ged", format = "csv", catalog = catalog)
#> # A tibble: 2 × 8
#>   dataset                  version variant section format url   file_name source
#>   <chr>                    <chr>   <chr>   <chr>   <chr>  <chr> <chr>     <chr> 
#> 1 UCDP Georeferenced Even… 25.1    NA      Disagg… csv    http… ged-251.… curre…
#> 2 UCDP Georeferenced Even… 24.1    NA      Disagg… csv    http… ged-241.… histo…
if (FALSE) { # \dontrun{
ucdp_versions("ged", format = "csv")
ucdp_versions("candidate", format = "csv")
} # }
```
