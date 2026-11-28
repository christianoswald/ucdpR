# Evaluate UCDP results across explicit analytical assumptions

`ucdp_sensitivity()` applies fatality scenarios and optional precision
filters to a common data set. It can return each transformed data set or
apply a user-supplied analysis function to every specification.

## Usage

``` r
ucdp_sensitivity(
  data,
  scenarios = c("low", "best", "high"),
  where_prec = NULL,
  date_prec = NULL,
  fatality_missing = c("propagate", "remove", "error"),
  analysis = NULL,
  ...,
  error = c("stop", "record"),
  precision_missing = c("drop", "keep", "error")
)
```

## Arguments

- data:

  A data frame containing fatality bounds.

- scenarios:

  Any of `"low"`, `"best"`, and `"high"`.

- where_prec, date_prec:

  Precision specifications. Supply `NULL`, one vector of accepted codes,
  or a named list of alternative code vectors.

- fatality_missing:

  Missing-value policy applied to fatality bounds. `"remove"` excludes
  observations with incomplete triplets before the sensitivity grid is
  evaluated.

- analysis:

  Optional function whose first argument receives a transformed data
  frame containing `.ucdp_fatalities`.

- ...:

  Additional arguments passed to `analysis`.

- error:

  Should analysis errors stop immediately or be recorded?

- precision_missing:

  Missing-value policy passed to
  [`ucdp_filter_precision()`](https://christianoswald.github.io/ucdpR/reference/ucdp_filter_precision.md).

## Value

An object with a specification table, result table, and, when
`analysis = NULL`, the transformed data sets.

## Examples

``` r
events <- data.frame(
  id = 1:3, low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 5, 6),
  where_prec = c(1, 2, 6)
)
sensitivity <- ucdp_sensitivity(
  events,
  where_prec = list(all = NULL, precise = 1:2),
  analysis = function(x) c(total = sum(x$.ucdp_fatalities))
)
sensitivity$results
#> # A tibble: 6 × 5
#>   .specification .scenario .where_precision .date_precision total
#>            <int> <chr>     <chr>            <chr>           <dbl>
#> 1              1 low       all              all                 6
#> 2              2 low       precise          all                 3
#> 3              3 best      all              all                 9
#> 4              4 best      precise          all                 5
#> 5              5 high      all              all                14
#> 6              6 high      precise          all                 8
```
