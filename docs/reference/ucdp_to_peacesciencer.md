# Prepare UCDP data for peacesciencer workflows

`ucdp_to_peacesciencer()` standardizes state-year or dyad-year keys to
the names expected by `peacesciencer` and declares the corresponding
package attributes. It does not aggregate event data automatically; use
[`ucdp_aggregate()`](https://christianoswald.github.io/ucdpR/reference/ucdp_aggregate.md)
first when observations are not already unique at the requested unit.

## Usage

``` r
ucdp_to_peacesciencer(
  data,
  type = c("state-year", "dyad-year"),
  system = c("gw", "cow"),
  code = NULL,
  code2 = NULL,
  year = "year",
  from = system,
  crosswalk = NULL,
  check_unique = TRUE
)
```

## Arguments

- data:

  A state-year or dyad-year data frame.

- type:

  `"state-year"` or `"dyad-year"`.

- system:

  Target state system: `"gw"` or `"cow"`.

- code, code2:

  Source code columns. `code2` is required for dyad-years.

- year:

  Year column.

- from:

  Coding system of the supplied codes. Defaults to `system`. If it
  differs, codes are converted with
  [`ucdp_country_crosswalk()`](https://christianoswald.github.io/ucdpR/reference/ucdp_country_crosswalk.md).

- crosswalk:

  Optional frozen crosswalk passed to
  [`ucdp_country_crosswalk()`](https://christianoswald.github.io/ucdpR/reference/ucdp_country_crosswalk.md).

- check_unique:

  Require one row per state-year or dyad-year key?

## Value

A data frame with `year` and `gwcode`/`ccode` keys (or numbered dyadic
variants) and `peacesciencer` attributes.

## Examples

``` r
x <- data.frame(country_id = c(2, 20), year = 2020, events = c(1, 3))
if (requireNamespace("peacesciencer", quietly = TRUE)) {
  ps <- ucdp_to_peacesciencer(x, code = "country_id")
}
```
