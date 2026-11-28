# Uncertainty workflows

Uncertainty in UCDP data is multidimensional. Fatality bounds describe
the reported low, best, and high estimates. Spatial and temporal
precision codes describe how precisely an event is located in place and
time. Retrospective revisions describe changes between releases. These
quantities answer different questions, and `ucdpR` does not collapse
them into a single score.

The examples below are fully offline and use small synthetic data.

``` r

library(ucdpR)

events <- data.frame(
  id = 1:6,
  year = c(2020, 2020, 2020, 2021, 2021, 2021),
  low = c(1, 2, 0, 4, 1, NA),
  best = c(2, 3, 1, 5, 2, NA),
  high = c(4, 5, 2, 8, 4, NA),
  where_prec = c(1, 2, 3, 1, 6, 2),
  date_prec = c(1, 2, 4, 1, 5, 2),
  type_of_violence = c(1, 1, 2, 3, 1, 2)
)
```

## Inventory reported uncertainty

Begin with a descriptive inventory. This reveals incomplete fatality
triplets, the width of complete fatality bounds, and the distribution of
precision codes.

``` r

ucdp_uncertainty(events)
#> # A tibble: 16 × 4
#>    dimension metric             value n_observations
#>    <chr>     <chr>              <dbl>          <int>
#>  1 fatality  n_complete         5                  6
#>  2 fatality  n_partial          0                  6
#>  3 fatality  n_all_missing      1                  6
#>  4 fatality  share_complete     0.833              6
#>  5 fatality  mean_bound_width   3                  6
#>  6 fatality  median_bound_width 3                  6
#>  7 spatial   n_missing          0                  6
#>  8 spatial   n_exact            2                  6
#>  9 spatial   share_exact        0.333              6
#> 10 spatial   mean_code          2.5                6
#> 11 spatial   maximum_code       6                  6
#> 12 temporal  n_missing          0                  6
#> 13 temporal  n_exact            2                  6
#> 14 temporal  share_exact        0.333              6
#> 15 temporal  mean_code          2.5                6
#> 16 temporal  maximum_code       5                  6
ucdp_uncertainty(events, by = "year")
#> # A tibble: 32 × 5
#>     year dimension metric             value n_observations
#>    <dbl> <chr>     <chr>              <dbl>          <int>
#>  1  2020 fatality  n_complete         3                  3
#>  2  2020 fatality  n_partial          0                  3
#>  3  2020 fatality  n_all_missing      0                  3
#>  4  2020 fatality  share_complete     1                  3
#>  5  2020 fatality  mean_bound_width   2.67               3
#>  6  2020 fatality  median_bound_width 3                  3
#>  7  2020 spatial   n_missing          0                  3
#>  8  2020 spatial   n_exact            1                  3
#>  9  2020 spatial   share_exact        0.333              3
#> 10  2020 spatial   mean_code          2                  3
#> # ℹ 22 more rows
```

The output keeps fatality, spatial, and temporal dimensions separate. A
wider fatality range is not interchangeable with a less precise
location.

## Treat reported bounds as scenarios

[`ucdp_scenarios()`](https://christianoswald.github.io/ucdpR/reference/ucdp_scenarios.md)
creates explicit low, best, and high analytical scenarios. The bounds
are not treated as confidence or credible intervals.

``` r

scenario_rows <- ucdp_scenarios(events)
head(scenario_rows)
#> # A tibble: 6 × 7
#>      id  year where_prec date_prec type_of_violence fatality_scenario fatalities
#>   <int> <dbl>      <dbl>     <dbl>            <dbl> <chr>                  <dbl>
#> 1     1  2020          1         1                1 low                        1
#> 2     2  2020          2         2                1 low                        2
#> 3     3  2020          3         4                2 low                        0
#> 4     4  2021          1         1                3 low                        4
#> 5     5  2021          6         5                1 low                        1
#> 6     6  2021          2         2                2 low                       NA

year_scenarios <- ucdp_scenarios(
  events,
  by = "year",
  format = "wide",
  fatality_missing = "remove"
)
year_scenarios
#> # A tibble: 2 × 7
#>    year n_observations n_complete n_missing fatalities_low fatalities_best
#>   <dbl>          <int>      <int>     <int>          <dbl>           <dbl>
#> 1  2020              3          3         0              3               6
#> 2  2021              3          2         1              5               7
#> # ℹ 1 more variable: fatalities_high <dbl>
```

Scenario differences can be made explicit:

``` r

ucdp_compare_scenarios(scenario_rows, by = "id")
#> # A tibble: 18 × 7
#>       id fatality_scenario fatalities reference_scenario reference_value
#>    <int> <chr>                  <dbl> <chr>                        <dbl>
#>  1     1 low                        1 best                             2
#>  2     2 low                        2 best                             3
#>  3     3 low                        0 best                             1
#>  4     4 low                        4 best                             5
#>  5     5 low                        1 best                             2
#>  6     6 low                       NA best                            NA
#>  7     1 best                       2 best                             2
#>  8     2 best                       3 best                             3
#>  9     3 best                       1 best                             1
#> 10     4 best                       5 best                             5
#> 11     5 best                       2 best                             2
#> 12     6 best                      NA best                            NA
#> 13     1 high                       4 best                             2
#> 14     2 high                       5 best                             3
#> 15     3 high                       2 best                             1
#> 16     4 high                       8 best                             5
#> 17     5 high                       4 best                             2
#> 18     6 high                      NA best                            NA
#> # ℹ 2 more variables: difference <dbl>, relative_difference <dbl>
```

## Sample only under a stated assumption

[`ucdp_sample_fatalities()`](https://christianoswald.github.io/ucdpR/reference/ucdp_sample_fatalities.md)
is experimental. It samples integer fatalities between the reported
bounds under a user-selected uniform or triangular distribution. UCDP
does not imply either distribution: it is an analytical assumption that
must be reported and defended.

``` r

complete_events <- events[stats::complete.cases(
  events[c("low", "best", "high")]
), ]

draws <- ucdp_sample_fatalities(
  complete_events,
  n = 5,
  distribution = "triangular",
  seed = 2026,
  id = "id"
)
head(draws)
#> # A tibble: 6 × 3
#>      id .draw fatalities
#>   <int> <int>      <int>
#> 1     1     1          3
#> 2     1     2          2
#> 3     1     3          2
#> 4     1     4          2
#> 5     1     5          2
#> 6     2     1          2
attr(draws, "ucdp_sampling_spec")
#> $n
#> [1] 5
#> 
#> $distribution
#> [1] "triangular"
#> 
#> $seed
#> [1] 2026
#> 
#> $id
#> [1] "id"
#> 
#> $fatality_columns
#>    low   best   high 
#>  "low" "best" "high" 
#> 
#> $missing
#> [1] "error"
#> 
#> $interpretation
#> [1] "Analyst-assumed distribution within UCDP bounds"
```

Supplying a seed makes the result reproducible without replacing the
caller’s existing random-number state. The returned specification
records the chosen distribution and column mapping.

## Run a sensitivity grid

[`ucdp_sensitivity()`](https://christianoswald.github.io/ucdpR/reference/ucdp_sensitivity.md)
crosses fatality scenarios with named precision rules. An analysis
function can return one number, a named vector, or a one-row data frame
for each specification.

``` r

sensitivity <- ucdp_sensitivity(
  complete_events,
  scenarios = c("low", "best", "high"),
  where_prec = list(all = NULL, precise = 1:2),
  date_prec = list(all = NULL, precise = 1:2),
  analysis = function(x) {
    c(events = nrow(x), fatalities = sum(x$.ucdp_fatalities))
  }
)

sensitivity$specifications
#> # A tibble: 12 × 7
#>    .specification .scenario .where_precision .date_precision n_rows status error
#>             <int> <chr>     <chr>            <chr>            <int> <chr>  <chr>
#>  1              1 low       all              all                  5 ok     NA   
#>  2              2 low       all              precise              3 ok     NA   
#>  3              3 low       precise          all                  3 ok     NA   
#>  4              4 low       precise          precise              3 ok     NA   
#>  5              5 best      all              all                  5 ok     NA   
#>  6              6 best      all              precise              3 ok     NA   
#>  7              7 best      precise          all                  3 ok     NA   
#>  8              8 best      precise          precise              3 ok     NA   
#>  9              9 high      all              all                  5 ok     NA   
#> 10             10 high      all              precise              3 ok     NA   
#> 11             11 high      precise          all                  3 ok     NA   
#> 12             12 high      precise          precise              3 ok     NA
sensitivity$results
#> # A tibble: 12 × 6
#>    .specification .scenario .where_precision .date_precision events fatalities
#>             <int> <chr>     <chr>            <chr>            <dbl>      <dbl>
#>  1              1 low       all              all                  5          8
#>  2              2 low       all              precise              3          7
#>  3              3 low       precise          all                  3          7
#>  4              4 low       precise          precise              3          7
#>  5              5 best      all              all                  5         13
#>  6              6 best      all              precise              3         10
#>  7              7 best      precise          all                  3         10
#>  8              8 best      precise          precise              3         10
#>  9              9 high      all              all                  5         23
#> 10             10 high      all              precise              3         17
#> 11             11 high      precise          all                  3         17
#> 12             12 high      precise          precise              3         17
```

Compare the fatality result with the best estimate within each precision
rule:

``` r

ucdp_compare_scenarios(
  sensitivity,
  value = "fatalities",
  by = c(".where_precision", ".date_precision")
)
#> # A tibble: 12 × 8
#>    .where_precision .date_precision .scenario fatalities reference_scenario
#>    <chr>            <chr>           <chr>          <dbl> <chr>             
#>  1 all              all             low                8 best              
#>  2 all              precise         low                7 best              
#>  3 precise          all             low                7 best              
#>  4 precise          precise         low                7 best              
#>  5 all              all             best              13 best              
#>  6 all              precise         best              10 best              
#>  7 precise          all             best              10 best              
#>  8 precise          precise         best              10 best              
#>  9 all              all             high              23 best              
#> 10 all              precise         high              17 best              
#> 11 precise          all             high              17 best              
#> 12 precise          precise         high              17 best              
#> # ℹ 3 more variables: reference_value <dbl>, difference <dbl>,
#> #   relative_difference <dbl>
```

These comparisons show sensitivity to specified analytical decisions;
they do not estimate the probability that any scenario is true.

## Prepare input for uncertainUCDP

[`ucdp_to_uncertainUCDP()`](https://christianoswald.github.io/ucdpR/reference/ucdp_to_uncertainUCDP.md)
is a narrow adapter. It maps a fatality column and UCDP type-of-violence
codes to the `fatalities` and `tov` arguments used by `uncertainUCDP`.
It validates the mapping but does not fit or reproduce the external
package’s statistical model.

``` r

prepared <- ucdp_to_uncertainUCDP(
  complete_events,
  fatalities = "best",
  type_of_violence = "type_of_violence",
  check_package = FALSE
)
prepared[c(".ucdp_fatalities", ".ucdp_tov")]
#> # A tibble: 5 × 2
#>   .ucdp_fatalities .ucdp_tov
#>              <dbl> <chr>    
#> 1                2 sb       
#> 2                3 sb       
#> 3                1 ns       
#> 4                5 os       
#> 5                2 sb
```

After installing `uncertainUCDP`, the prepared columns can be passed
explicitly to its simulation function:

``` r

simulated <- uncertainUCDP::runcertainUCDP(
  n = nrow(prepared),
  fatalities = prepared$.ucdp_fatalities,
  tov = prepared$.ucdp_tov
)
```

Consult the `uncertainUCDP` documentation and cite that package when
using its model. Preserve the exact UCDP release, source metadata, and
all assumptions in the research record.
