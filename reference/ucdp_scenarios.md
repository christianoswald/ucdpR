# Construct low, best, and high fatality scenarios

`ucdp_scenarios()` retains UCDP's three reported fatality estimates as
explicit analytical scenarios. They are not interpreted as probability
or confidence intervals.

## Usage

``` r
ucdp_scenarios(
  data,
  by = NULL,
  low = NULL,
  best = NULL,
  high = NULL,
  format = c("long", "wide"),
  fatality_missing = c("propagate", "remove", "error")
)
```

## Arguments

- data:

  A data frame containing fatality estimates.

- by:

  Optional grouping columns. When supplied, fatalities are summed within
  groups before scenarios are constructed.

- low, best, high:

  Optional fatality-bound columns.

- format:

  Return scenarios in long or wide form.

- fatality_missing:

  Missing-value policy used for grouped sums. See
  [`ucdp_fatalities()`](https://christianoswald.github.io/ucdpR/reference/ucdp_fatalities.md).
  For ungrouped data, `"error"` rejects missing bounds; other policies
  retain them.

## Value

A tibble with explicit scenario metadata and preserved provenance.

## Examples

``` r
events <- data.frame(
  id = 1:3, year = c(2020, 2020, 2021),
  low = c(1, 2, 3), best = c(2, 3, 4), high = c(3, 5, 6)
)
ucdp_scenarios(events)
#> # A tibble: 9 × 4
#>      id  year fatality_scenario fatalities
#>   <int> <dbl> <chr>                  <dbl>
#> 1     1  2020 low                        1
#> 2     2  2020 low                        2
#> 3     3  2021 low                        3
#> 4     1  2020 best                       2
#> 5     2  2020 best                       3
#> 6     3  2021 best                       4
#> 7     1  2020 high                       3
#> 8     2  2020 high                       5
#> 9     3  2021 high                       6
ucdp_scenarios(events, by = "year", format = "wide")
#> # A tibble: 2 × 7
#>    year n_observations n_complete n_missing fatalities_low fatalities_best
#>   <dbl>          <int>      <int>     <int>          <dbl>           <dbl>
#> 1  2020              2          2         0              3               5
#> 2  2021              1          1         0              3               4
#> # ℹ 1 more variable: fatalities_high <dbl>
```
