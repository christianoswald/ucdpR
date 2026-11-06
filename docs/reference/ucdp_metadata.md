# Summarize UCDP provenance and data coverage

`ucdp_metadata()` returns a standardized, one-row summary for an
imported UCDP object, a path returned by
[`ucdp_download()`](https://christianoswald.github.io/ucdpR/reference/ucdp_download.md),
or a dataset available in the official catalog. Objects imported by
[`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md)
retain the richest provenance information.

## Usage

``` r
ucdp_metadata(
  x,
  dataset = NULL,
  version = NULL,
  variant = NULL,
  format = "csv",
  catalog = NULL,
  quiet = FALSE
)
```

## Arguments

- x:

  A data object, downloaded path, or dataset name or alias.

- dataset:

  Optional dataset label used for an object without provenance.

- version:

  Optional exact release when `x` is a dataset name.

- variant:

  Optional dataset variant when `x` is a dataset name.

- format:

  File format used to resolve a catalog entry.

- catalog:

  Optional pre-fetched catalog.

- quiet:

  Suppress catalog messages?

## Value

A one-row tibble containing provenance, dimensions, and available
temporal and geographic coverage.

## Examples

``` r
example <- data.frame(year = 2020:2022, latitude = c(1, 2, 3),
                      longitude = c(4, 5, 6))
ucdp_metadata(example, dataset = "Example UCDP data")
#> # A tibble: 1 × 20
#>   dataset           version variant format file_name source_url catalog_source
#>   <chr>             <chr>   <chr>   <chr>  <chr>     <chr>      <chr>         
#> 1 Example UCDP data NA      NA      NA     NA        NA         NA            
#> # ℹ 13 more variables: retrieved_at <chr>, md5 <chr>, ucdpR_version <chr>,
#> #   n_rows <int>, n_columns <int>, year_min <int>, year_max <int>,
#> #   date_min <chr>, date_max <chr>, latitude_min <dbl>, latitude_max <dbl>,
#> #   longitude_min <dbl>, longitude_max <dbl>
if (FALSE) { # \dontrun{
ged <- ucdp_get("ged", version = "25.1")
ucdp_metadata(ged)
ucdp_metadata("ged", version = "25.1")
} # }
```
