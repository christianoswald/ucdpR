# Inspect the structure of a UCDP dataset

`ucdp_schema()` reports storage classes, missingness, uniqueness,
ranges, and example values. It accepts an existing data frame or a
dataset name that can be passed to
[`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md).

## Usage

``` r
ucdp_schema(
  x,
  version = NULL,
  variant = NULL,
  format = "csv",
  quiet = FALSE,
  ...
)
```

## Arguments

- x:

  A data frame, or a dataset name or alias.

- version, variant, format, quiet:

  Passed to
  [`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md)
  when `x` is a dataset name.

- ...:

  Additional arguments passed to
  [`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md).

## Value

A tibble with one row per variable. Its `ucdp_metadata` attribute
contains a provenance summary for the inspected data.

## Examples

``` r
events <- data.frame(
  id = 1:3, year = c(2020, 2021, NA), country = c("A", "A", "B")
)
schema <- ucdp_schema(events)
schema[c("variable", "class", "pct_missing", "n_unique")]
#> # A tibble: 3 × 4
#>   variable class     pct_missing n_unique
#>   <chr>    <chr>           <dbl>    <int>
#> 1 id       integer         0            3
#> 2 year     numeric         0.333        2
#> 3 country  character       0            2
if (FALSE) ucdp_schema("ged", version = "25.1") # \dontrun{}
```
