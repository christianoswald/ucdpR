# Compare fatality scenarios or sensitivity results

Compare fatality scenarios or sensitivity results

## Usage

``` r
ucdp_compare_scenarios(
  x,
  reference = "best",
  value = NULL,
  by = NULL,
  relative = TRUE
)
```

## Arguments

- x:

  Long output from
  [`ucdp_scenarios()`](https://christianoswald.github.io/ucdpR/reference/ucdp_scenarios.md)
  or an analyzed `ucdp_sensitivity` object.

- reference:

  Reference scenario.

- value:

  Numeric result column. It is detected only when unambiguous.

- by:

  Optional comparison-key columns. By default, all non-result,
  non-scenario specification columns are used.

- relative:

  Include relative differences from the reference?

## Value

A tibble containing scenario values, reference values, and absolute and
optional relative differences.

## Examples

``` r
events <- data.frame(
  id = 1:2, low = c(1, 2), best = c(2, 3), high = c(4, 5)
)
scenarios <- ucdp_scenarios(events)
ucdp_compare_scenarios(scenarios, by = "id")
#> # A tibble: 6 × 7
#>      id fatality_scenario fatalities reference_scenario reference_value
#>   <int> <chr>                  <dbl> <chr>                        <dbl>
#> 1     1 low                        1 best                             2
#> 2     2 low                        2 best                             3
#> 3     1 best                       2 best                             2
#> 4     2 best                       3 best                             3
#> 5     1 high                       4 best                             2
#> 6     2 high                       5 best                             3
#> # ℹ 2 more variables: difference <dbl>, relative_difference <dbl>
```
