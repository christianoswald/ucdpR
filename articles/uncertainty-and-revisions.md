# Uncertainty, precision, and retrospective revisions

UCDP data expose more than one form of uncertainty. Event records
include spatial and temporal precision codes, while successive releases
may revise previously published observations. `ucdpR` makes both
dimensions inspectable without converting them into a single substantive
uncertainty measure.

``` r

library(ucdpR)

events <- data.frame(
  id = 1:5,
  year = c(2020, 2020, 2021, 2021, 2021),
  where_prec = c(1, 2, 3, 6, NA),
  date_prec = c(1, 2, 4, 5, 1),
  best = c(4, 8, 2, 12, 1)
)
```

## Precision as reported uncertainty

Begin by showing the distribution rather than immediately discarding
less precise observations.

``` r

ucdp_precision(events)
#> # A tibble: 9 × 6
#>   dimension variable    code label                                       n share
#>   <chr>     <chr>      <int> <chr>                                   <int> <dbl>
#> 1 spatial   where_prec     1 Exact location                              1   0.2
#> 2 spatial   where_prec     2 Within approximately 25 km                  1   0.2
#> 3 spatial   where_prec     3 Second-order administrative division        1   0.2
#> 4 spatial   where_prec     6 Country only                                1   0.2
#> 5 spatial   where_prec    NA Missing                                     1   0.2
#> 6 temporal  date_prec      1 Exact date                                  2   0.4
#> 7 temporal  date_prec      2 Two-to-six-day range                        1   0.2
#> 8 temporal  date_prec      4 Eight-to-thirty-day range or month kno…     1   0.2
#> 9 temporal  date_prec      5 More than one month but less than one …     1   0.2
ucdp_precision(events, by = "year")
#> # A tibble: 10 × 7
#>     year dimension variable    code label                                n share
#>    <dbl> <chr>     <chr>      <int> <chr>                            <int> <dbl>
#>  1  2020 spatial   where_prec     1 Exact location                       1 0.5  
#>  2  2020 spatial   where_prec     2 Within approximately 25 km           1 0.5  
#>  3  2021 spatial   where_prec     3 Second-order administrative div…     1 0.333
#>  4  2021 spatial   where_prec     6 Country only                         1 0.333
#>  5  2021 spatial   where_prec    NA Missing                              1 0.333
#>  6  2020 temporal  date_prec      1 Exact date                           1 0.5  
#>  7  2020 temporal  date_prec      2 Two-to-six-day range                 1 0.5  
#>  8  2021 temporal  date_prec      1 Exact date                           1 0.333
#>  9  2021 temporal  date_prec      4 Eight-to-thirty-day range or mo…     1 0.333
#> 10  2021 temporal  date_prec      5 More than one month but less th…     1 0.333
```

An analysis can then define transparent thresholds and compare results
across them.

``` r

strict_sample <- ucdp_filter_precision(
  events, where_prec = 1, date_prec = 1:2
)

broader_sample <- ucdp_filter_precision(
  events, where_prec = 1:3, date_prec = 1:4
)

nrow(strict_sample)
#> [1] 1
nrow(broader_sample)
#> [1] 3
```

## Revisions between releases

The comparison function accepts preloaded data frames, which makes the
core operation reproducible and easy to demonstrate without downloading
data.

``` r

old <- data.frame(
  id = 1:4,
  year = c(2020, 2020, 2021, 2021),
  best = c(4, 8, 2, 12),
  where_prec = c(1, 2, 3, 6),
  version = "24.1"
)

new <- data.frame(
  id = 2:5,
  year = c(2020, 2021, 2021, 2021),
  best = c(8, 3, 12, 1),
  where_prec = c(2, 2, 6, 1),
  version = "25.1"
)

comparison <- ucdp_compare_versions(
  "ged",
  old_version = "24.1",
  new_version = "25.1",
  key = "id",
  old_data = old,
  new_data = new
)

comparison$overview
#> # A tibble: 1 × 7
#>   old_rows new_rows matched added removed modified unchanged
#>      <int>    <int>   <int> <int>   <int>    <int>     <int>
#> 1        4        4       3     1       1        1         2
comparison$variables
#> # A tibble: 3 × 2
#>   variable   n_changed
#>   <chr>          <int>
#> 1 best               1
#> 2 where_prec         1
#> 3 year               0
comparison$added
#> # A tibble: 1 × 5
#>      id  year  best where_prec version
#>   <int> <dbl> <dbl>      <dbl> <chr>  
#> 1     5  2021     1          1 25.1
comparison$removed
#> # A tibble: 1 × 5
#>      id  year  best where_prec version
#>   <int> <dbl> <dbl>      <dbl> <chr>  
#> 1     1  2020     4          1 24.1
comparison$modified
#> # A tibble: 1 × 2
#>      id changed_columns 
#>   <int> <chr>           
#> 1     3 best, where_prec
```

Cell-level output is useful when the direction and magnitude of
individual changes matter.

``` r

cell_comparison <- ucdp_compare_versions(
  "ged", "24.1", "25.1",
  key = "id", old_data = old, new_data = new,
  detail = "cells"
)
cell_comparison$cell_changes
#> # A tibble: 2 × 4
#>      id variable   old_value new_value
#>   <int> <chr>      <chr>     <chr>    
#> 1     3 best       2         3        
#> 2     3 where_prec 3         2
```

For official releases, omit `old_data` and `new_data` and supply exact
version identifiers:

``` r

official_comparison <- ucdp_compare_versions(
  "ged", old_version = "24.1", new_version = "25.1"
)
```

Revision frequency is not automatically measurement error: changes may
reflect new information, corrected coding, altered definitions, or
expanded coverage. The comparison identifies what changed; substantive
interpretation still requires the relevant codebooks and version
histories.

Direct integration with `uncertainUCDP` will be documented after its
current API and the meaning of the exchanged objects have been verified.
Until then, the outputs remain ordinary tibbles that can be inspected or
transformed by downstream uncertainty workflows without an undocumented
dependency.
