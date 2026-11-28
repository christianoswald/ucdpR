# Prepare UCDP event data for uncertainUCDP

`ucdp_to_uncertainUCDP()` validates and adds the vectors expected by
`uncertainUCDP` 0.7.6: reported fatalities and a violence-type code. It
does not call or reproduce that package's statistical model.

## Usage

``` r
ucdp_to_uncertainUCDP(
  data,
  fatalities = NULL,
  type_of_violence = NULL,
  missing = c("error", "drop", "keep"),
  check_package = TRUE
)
```

## Arguments

- data:

  Event-level UCDP data.

- fatalities:

  Reported-fatality column. Common best-estimate columns are detected
  when omitted.

- type_of_violence:

  Violence-type column. Common UCDP names are detected when omitted.

- missing:

  How to handle rows with missing fatalities or violence type.

- check_package:

  If `uncertainUCDP` is installed, verify that its version is at least
  0.7.6.

## Value

A tibble retaining the original columns and adding `.ucdp_fatalities`
and `.ucdp_tov`.

## Examples

``` r
events <- data.frame(
  id = 1:3, best = c(2, 5, 1), type_of_violence = c(1, 2, 3)
)
prepared <- ucdp_to_uncertainUCDP(events, check_package = FALSE)
prepared[c(".ucdp_fatalities", ".ucdp_tov")]
#> # A tibble: 3 × 2
#>   .ucdp_fatalities .ucdp_tov
#>              <dbl> <chr>    
#> 1                2 sb       
#> 2                5 ns       
#> 3                1 os       
```
