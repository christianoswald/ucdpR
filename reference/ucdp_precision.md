# Summarize spatial and temporal precision in UCDP event data

Summarize spatial and temporal precision in UCDP event data

## Usage

``` r
ucdp_precision(data, by = NULL, include_missing = TRUE)
```

## Arguments

- data:

  A data frame containing `where_prec` and/or `date_prec`.

- by:

  Optional grouping columns, such as `"year"` or `c("country", "year")`.

- include_missing:

  Include missing precision values in the summary?

## Value

A tibble with grouping variables, precision dimension, code, label,
count, and within-group share.

## Examples

``` r
events <- data.frame(
  year = c(2020, 2020, 2021),
  where_prec = c(1, 2, 2), date_prec = c(1, 1, 3)
)
ucdp_precision(events)
#> # A tibble: 4 × 6
#>   dimension variable    code label                          n share
#>   <chr>     <chr>      <int> <chr>                      <int> <dbl>
#> 1 spatial   where_prec     1 Exact location                 1 0.333
#> 2 spatial   where_prec     2 Within approximately 25 km     2 0.667
#> 3 temporal  date_prec      1 Exact date                     2 0.667
#> 4 temporal  date_prec      3 Week known                     1 0.333
ucdp_precision(events, by = "year")
#> # A tibble: 5 × 7
#>    year dimension variable    code label                          n share
#>   <dbl> <chr>     <chr>      <int> <chr>                      <int> <dbl>
#> 1  2020 spatial   where_prec     1 Exact location                 1   0.5
#> 2  2020 spatial   where_prec     2 Within approximately 25 km     1   0.5
#> 3  2021 spatial   where_prec     2 Within approximately 25 km     1   1  
#> 4  2020 temporal  date_prec      1 Exact date                     2   1  
#> 5  2021 temporal  date_prec      3 Week known                     1   1  
```
