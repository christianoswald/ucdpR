# Summarize UCDP fatality estimates

`ucdp_fatalities()` aggregates the low, best, and high fatality
estimates while retaining information about incomplete observations. It
recognizes common UCDP triplets such as `low`/`best`/`high` and
`bd_low`/`bd_best`/`bd_high`.

## Usage

``` r
ucdp_fatalities(
  data,
  by = NULL,
  low = NULL,
  best = NULL,
  high = NULL,
  na_rm = TRUE,
  fatality_missing = NULL,
  missing = c("drop", "error")
)
```

## Arguments

- data:

  A data frame containing fatality estimates.

- by:

  Optional grouping columns.

- low, best, high:

  Optional column names for the three estimates. Supply all three or
  none. When omitted, common UCDP names are detected.

- na_rm:

  Backward-compatible logical control for missing fatality values.
  `TRUE` corresponds to `fatality_missing = "remove"`; `FALSE`
  corresponds to `fatality_missing = "propagate"`.

- fatality_missing:

  Explicit missing-value policy for fatality sums. `"remove"` returns
  partial totals together with completeness counts, `"propagate"`
  returns `NA` when any contributing estimate is missing, and `"error"`
  stops before aggregation. When `NULL`, `na_rm` determines the policy.

- missing:

  How to handle missing grouping values: drop their rows or raise an
  error.

## Value

A tibble containing grouping variables, observation counts, completeness
counts, and aggregated low, best, and high estimates.

## Examples

``` r
events <- data.frame(
  country = c("A", "A", "B"),
  low = c(1, 2, NA), best = c(2, 3, 4), high = c(3, 5, 6)
)
ucdp_fatalities(events)
#> # A tibble: 1 × 6
#>   n_observations n_complete n_missing fatalities_low fatalities_best
#>            <int>      <int>     <int>          <dbl>           <dbl>
#> 1              3          2         1              3               9
#> # ℹ 1 more variable: fatalities_high <dbl>
ucdp_fatalities(events, by = "country")
#> # A tibble: 2 × 7
#>   country n_observations n_complete n_missing fatalities_low fatalities_best
#>   <chr>            <int>      <int>     <int>          <dbl>           <dbl>
#> 1 A                    2          2         0              3               5
#> 2 B                    1          0         1             NA               4
#> # ℹ 1 more variable: fatalities_high <dbl>
```
