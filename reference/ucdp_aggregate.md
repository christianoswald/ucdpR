# Aggregate UCDP event data to common analytical units

`ucdp_aggregate()` constructs event counts and, when available,
aggregated fatality bounds for country, PRIO-GRID, conflict, or dyad
panels. Entity and time columns are detected from common UCDP names or
can be supplied explicitly.

## Usage

``` r
ucdp_aggregate(
  data,
  unit,
  id = NULL,
  date = NULL,
  by = NULL,
  include_fatalities = TRUE,
  low = NULL,
  best = NULL,
  high = NULL,
  na_rm = TRUE,
  missing = c("drop", "error")
)
```

## Arguments

- data:

  A data frame containing event-level or other disaggregated UCDP
  observations.

- unit:

  One of `"country-year"`, `"country-month"`, `"grid-year"`,
  `"grid-month"`, `"conflict-year"`, `"conflict-month"`, `"dyad-year"`,
  or `"dyad-month"`. Underscores are accepted in place of hyphens.

- id:

  Optional entity column or columns. When omitted, common names are
  detected for the selected unit.

- date:

  Optional date column used to derive year and month. Existing `year`
  and `month` columns are preferred when both are available.

- by:

  Additional grouping columns retained in the output.

- include_fatalities:

  Include aggregated fatality estimates when a recognized triplet is
  present?

- low, best, high:

  Optional fatality columns passed to the same detection logic as
  [`ucdp_fatalities()`](https://christianoswald.github.io/ucdpR/reference/ucdp_fatalities.md).

- na_rm:

  Missing-value behavior for fatality sums; see
  [`ucdp_fatalities()`](https://christianoswald.github.io/ucdpR/reference/ucdp_fatalities.md).

- missing:

  How to handle missing entity, time, or additional grouping values:
  drop their rows or raise an error.

## Value

A tibble with one row per unit-period combination, `n_events`, and, when
available, fatality totals and completeness counts. Provenance and an
aggregation specification are attached as attributes.

## Examples

``` r
events <- data.frame(
  country_id = c(1, 1, 1, 2), country = c("A", "A", "A", "B"),
  year = c(2020, 2020, 2021, 2020),
  low = c(0, 1, 2, 1), best = c(1, 2, 3, 2), high = c(2, 3, 4, 3)
)
ucdp_aggregate(events, unit = "country-year")
#> # A tibble: 3 × 9
#>   country_id country  year n_events n_fatality_complete n_fatality_missing
#>        <dbl> <chr>   <int>    <int>               <int>              <int>
#> 1          1 A        2020        2                   2                  0
#> 2          1 A        2021        1                   1                  0
#> 3          2 B        2020        1                   1                  0
#> # ℹ 3 more variables: fatalities_low <dbl>, fatalities_best <dbl>,
#> #   fatalities_high <dbl>
```
