# Interoperability with priogrid and peacesciencer

`ucdpR` uses the identifiers native to two established peace-science
tools: `pgid` for the released `priogrid` package and `gwcode`/`ccode`
plus `year` for `peacesciencer`. The bridges preserve UCDP provenance
and keep consequential matching and aggregation decisions explicit.

## Year-sensitive country codes

State systems change over time, so country codes should not be
translated with an ahistorical lookup table.
[`ucdp_country_crosswalk()`](https://christianoswald.github.io/ucdpR/reference/ucdp_country_crosswalk.md)
matches on both code and year. It normally asks `peacesciencer` to
construct the mapping; a frozen crosswalk can be supplied for an offline
replication.

``` r

library(ucdpR)

country_year <- data.frame(
  country_id = c(2, 20, 2),
  year = c(2020, 2020, 2021),
  n_events = c(3, 1, 4)
)

frozen_codes <- data.frame(
  year = c(2020, 2020, 2021),
  gwcode = c(2, 20, 2),
  ccode = c(2, 20, 2)
)

ucdp_country_crosswalk(
  country_year,
  from = "gw",
  code = "country_id",
  crosswalk = frozen_codes
)
#> # A tibble: 3 × 4
#>   country_id  year n_events ccode
#>        <dbl> <dbl>    <dbl> <int>
#> 1          2  2020        3     2
#> 2         20  2020        1    20
#> 3          2  2021        4     2
```

Choose `unmatched = "warn"` or `"error"` during quality control. The
returned `ucdp_crosswalk` attribute records match counts and the mapping
source.

## peacesciencer

[`ucdp_to_peacesciencer()`](https://christianoswald.github.io/ucdpR/reference/ucdp_to_peacesciencer.md)
renames or converts identifiers and calls
[`peacesciencer::declare_attributes()`](https://rdrr.io/pkg/peacesciencer/man/declare_attributes.html).
Input must already be unique at the requested unit. For event data,
aggregate first:

``` r

state_year <- ucdp_aggregate(ged, unit = "country-year")

ps_state_year <- ucdp_to_peacesciencer(
  state_year,
  type = "state-year",
  system = "gw",
  code = "country_id"
)

# peacesciencer functions can now recognize the data type and state system
ps_state_year <- peacesciencer::add_nmc(ps_state_year)
```

Dyad-year data use `code` and `code2` and become `gwcode1`/`gwcode2` or
`ccode1`/`ccode2`. If `from` and `system` differ, supply a frozen
crosswalk or allow `peacesciencer` to build the year-specific
conversion.

## priogrid

Install the released `priogrid` package according to its website. It is
not a hard dependency of `ucdpR`.

``` r

renv::install("prio-data/priogrid")

ged_pg <- ucdp_to_priogrid(ged)
grid_year <- ucdp_aggregate(ged_pg, unit = "grid-year", id = "pgid")
```

By default,
[`ucdp_to_priogrid()`](https://christianoswald.github.io/ucdpR/reference/ucdp_to_priogrid.md)
extracts identifiers from `priogrid::prio_blank_grid()`, respecting its
current configuration. For a frozen analysis, save that one-layer
`SpatRaster` and pass it as `grid`. This also makes the analysis
independent of later changes to package defaults.

Coordinates outside the grid or missing coordinates produce `NA` by
default. Use `missing = "drop"` or `"error"` to make a different policy
explicit.

The bridge returns the conventional `pgid` column rather than a private
class. That keeps it directly usable with `priogrid` tables today and
leaves a stable interface for the planned `priogridR` package later.
