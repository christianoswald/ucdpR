# Construct complete UCDP analytical panels

`ucdp_panel()` completes the entity-period combinations in an aggregated
data set. It can also aggregate raw data first when `unit` is supplied.
Inserted rows are always identified by `.ucdp_observed` and
`.ucdp_fill`, so zero-filled combinations are never indistinguishable
from source groups.

## Usage

``` r
ucdp_panel(
  data,
  unit = NULL,
  id = NULL,
  date = NULL,
  by = NULL,
  start = NULL,
  end = NULL,
  universe = NULL,
  fill = c("zero", "missing"),
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

  Raw UCDP observations or output from
  [`ucdp_aggregate()`](https://christianoswald.github.io/ucdpR/reference/ucdp_aggregate.md).

- unit:

  Aggregation unit used for raw data. It may be omitted when `data`
  retains the `ucdp_aggregation` attribute.

- id, date, by, include_fatalities, low, best, high, na_rm:

  Passed to
  [`ucdp_aggregate()`](https://christianoswald.github.io/ucdpR/reference/ucdp_aggregate.md)
  when raw data are supplied.

- start, end:

  Panel boundaries. Use four-digit years for yearly panels and
  `"YYYY-MM"` strings or dates for monthly panels. Defaults to the
  observed range.

- universe:

  Optional entity universe. Supply a vector for a one-column entity key
  or a data frame containing all entity and `by` columns. The default
  uses combinations observed at least once in `data`.

- fill:

  Should inserted combinations contain explicit zeroes in numeric
  aggregate columns or missing values?

- missing:

  Passed to
  [`ucdp_aggregate()`](https://christianoswald.github.io/ucdpR/reference/ucdp_aggregate.md)
  for raw data.

## Value

A complete panel tibble. `.ucdp_observed` is `TRUE` only for groups
present in the aggregated input; `.ucdp_fill` is `"observed"`,
`"zero_filled"`, or `"missing"`.

## Examples

``` r
events <- data.frame(
  country_id = c(1, 1, 2), year = c(2020, 2022, 2021),
  low = c(0, 1, 2), best = c(1, 2, 3), high = c(2, 3, 4)
)
panel <- ucdp_panel(
  events, unit = "country-year", start = 2020, end = 2022
)
panel[c("country_id", "year", "n_events", ".ucdp_fill")]
#> # A tibble: 6 × 4
#>   country_id  year n_events .ucdp_fill 
#>        <dbl> <int>    <int> <chr>      
#> 1          1  2020        1 observed   
#> 2          1  2021        0 zero_filled
#> 3          1  2022        1 observed   
#> 4          2  2020        0 zero_filled
#> 5          2  2021        1 observed   
#> 6          2  2022        0 zero_filled
```
