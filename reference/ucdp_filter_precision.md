# Filter UCDP events by spatial and temporal precision

Filter UCDP events by spatial and temporal precision

## Usage

``` r
ucdp_filter_precision(
  data,
  where_prec = NULL,
  date_prec = NULL,
  missing = c("drop", "keep", "error")
)
```

## Arguments

- data:

  A data frame containing UCDP precision variables.

- where_prec:

  Spatial precision codes to retain. `NULL` applies no spatial filter.

- date_prec:

  Temporal precision codes to retain. `NULL` applies no temporal filter.

- missing:

  Whether missing values in an actively filtered precision variable
  should be dropped, retained, or treated as an error.

## Value

`data` restricted to the requested precision, with provenance and
spatial class retained.

## Examples

``` r
events <- data.frame(
  id = 1:4, where_prec = c(1, 2, 6, NA), date_prec = c(1, 3, 5, 1)
)
ucdp_filter_precision(events, where_prec = 1:2, date_prec = 1:3)
#>   id where_prec date_prec
#> 1  1          1         1
#> 2  2          2         3
ucdp_filter_precision(events, where_prec = 1:2, missing = "keep")
#>   id where_prec date_prec
#> 1  1          1         1
#> 2  2          2         3
#> 4  4         NA         1
```
