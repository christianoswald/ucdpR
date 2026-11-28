# Sample assumption-based fatality realizations within UCDP bounds

`ucdp_sample_fatalities()` is experimental. UCDP low and high estimates
do not define a probability distribution; every draw produced here
reflects the analyst-selected uniform or triangular assumption.

## Usage

``` r
ucdp_sample_fatalities(
  data,
  n = 100L,
  distribution = c("uniform", "triangular"),
  low = NULL,
  best = NULL,
  high = NULL,
  seed = NULL,
  id = NULL,
  format = c("long", "list"),
  missing = c("error", "propagate", "drop")
)
```

## Arguments

- data:

  A data frame containing low, best, and high fatalities.

- n:

  Number of realizations per observation.

- distribution:

  Sampling assumption. The triangular distribution uses the best
  estimate as its mode.

- low, best, high:

  Optional fatality-bound columns.

- seed:

  Optional non-negative integer seed. When supplied, the caller's
  existing random-number state is restored after sampling.

- id:

  Optional observation-identifier columns. A stable row number is
  created when omitted.

- format:

  Return one long tibble or a list containing one data frame per
  realization.

- missing:

  How to handle incomplete fatality triplets.

## Value

A tibble or list with sampled fatalities and recorded assumptions.

## Examples

``` r
events <- data.frame(
  id = 1:2, low = c(1, 4), best = c(2, 5), high = c(3, 8)
)
ucdp_sample_fatalities(events, n = 3, seed = 42)
#> # A tibble: 6 × 3
#>   .ucdp_row .draw fatalities
#>       <int> <int>      <int>
#> 1         1     1          1
#> 2         1     2          1
#> 3         1     3          1
#> 4         2     1          4
#> 5         2     2          5
#> 6         2     3          7
```
