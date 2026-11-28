# Inventory uncertainty-related information in UCDP data

`ucdp_uncertainty()` summarizes fatality bounds, missing fatality
estimates, and spatial and temporal precision codes. These dimensions
remain separate: the function does not combine them into an undocumented
uncertainty score.

## Usage

``` r
ucdp_uncertainty(
  data,
  by = NULL,
  low = NULL,
  best = NULL,
  high = NULL,
  where_prec = NULL,
  date_prec = NULL
)
```

## Arguments

- data:

  A data frame containing UCDP observations.

- by:

  Optional grouping columns.

- low, best, high:

  Optional fatality-bound columns. Supply all three or none.

- where_prec, date_prec:

  Optional spatial and temporal precision columns. Set either argument
  to `NA_character_` to omit that dimension. Common UCDP names are
  detected when the argument is `NULL`.

## Value

A tidy tibble with grouping columns, uncertainty dimension, metric,
value, and group size. Source metadata and detected column mappings are
attached as attributes.

## Examples

``` r
events <- data.frame(
  year = c(2020, 2020, 2021),
  low = c(1, 2, NA), best = c(2, 3, 4), high = c(3, 5, 6),
  where_prec = c(1, 2, 6), date_prec = c(1, 2, 4)
)
ucdp_uncertainty(events)
#> # A tibble: 16 × 4
#>    dimension metric             value n_observations
#>    <chr>     <chr>              <dbl>          <int>
#>  1 fatality  n_complete         2                  3
#>  2 fatality  n_partial          1                  3
#>  3 fatality  n_all_missing      0                  3
#>  4 fatality  share_complete     0.667              3
#>  5 fatality  mean_bound_width   2.5                3
#>  6 fatality  median_bound_width 2.5                3
#>  7 spatial   n_missing          0                  3
#>  8 spatial   n_exact            1                  3
#>  9 spatial   share_exact        0.333              3
#> 10 spatial   mean_code          3                  3
#> 11 spatial   maximum_code       6                  3
#> 12 temporal  n_missing          0                  3
#> 13 temporal  n_exact            1                  3
#> 14 temporal  share_exact        0.333              3
#> 15 temporal  mean_code          2.33               3
#> 16 temporal  maximum_code       4                  3
ucdp_uncertainty(events, by = "year")
#> # A tibble: 32 × 5
#>     year dimension metric             value n_observations
#>    <dbl> <chr>     <chr>              <dbl>          <int>
#>  1  2020 fatality  n_complete           2                2
#>  2  2020 fatality  n_partial            0                2
#>  3  2020 fatality  n_all_missing        0                2
#>  4  2020 fatality  share_complete       1                2
#>  5  2020 fatality  mean_bound_width     2.5              2
#>  6  2020 fatality  median_bound_width   2.5              2
#>  7  2020 spatial   n_missing            0                2
#>  8  2020 spatial   n_exact              1                2
#>  9  2020 spatial   share_exact          0.5              2
#> 10  2020 spatial   mean_code            1.5              2
#> # ℹ 22 more rows
```
