# Validate a UCDP dataset

`ucdp_validate()` performs transparent structural and range checks
commonly relevant to UCDP data. It does not alter the input and does not
claim that a flagged value is necessarily a coding error; warnings
identify records that merit inspection.

## Usage

``` r
ucdp_validate(data, dataset = NULL, key = NULL, checks = "all", strict = FALSE)
```

## Arguments

- data:

  A data frame containing UCDP data.

- dataset:

  Optional dataset label used in the returned metadata.

- key:

  Optional columns that should uniquely identify observations. When
  omitted, a plausible key is inferred from common UCDP identifiers.

- checks:

  Any of `"keys"`, `"dates"`, `"fatalities"`, `"coordinates"`, and
  `"codes"`, or `"all"`.

- strict:

  If `TRUE`, warnings also make the overall result invalid.

## Value

An object of class `ucdp_validation` with `valid`, `summary`, `issues`,
`key`, and `metadata` components.

## Examples

``` r
example <- data.frame(
  id = c(1, 2), year = c(2020, 2021),
  low = c(0, 2), best = c(1, 3), high = c(2, 4),
  latitude = c(10, 20), longitude = c(30, 40)
)
ucdp_validate(example)
#> UCDP data validation
#> Result: valid
#> Key: id
#> 
#> # A tibble: 5 × 3
#>   check       status  n_issues
#>   <chr>       <chr>      <int>
#> 1 keys        pass           0
#> 2 dates       skipped        0
#> 3 fatalities  pass           0
#> 4 coordinates pass           0
#> 5 codes       skipped        0
```
