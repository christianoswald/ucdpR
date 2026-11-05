# Getting started with ucdpR

`ucdpR` supports reproducible research with data from the Uppsala
Conflict Data Program. It discovers current and historical releases,
imports data, retains provenance, retrieves supporting documentation,
and provides tools for validation, spatial preparation, precision
assessment, and release comparison.

The usual live-data workflow is deliberately short:

``` r

library(ucdpR)

ucdp_search("georeferenced|candidate")
ged <- ucdp_get("ged", version = "25.1", format = "csv")
ucdp_metadata(ged)
ucdp_validate(ged)
```

Specifying a version makes the analytical input explicit. Objects
returned by
[`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md)
retain the selected catalog record, source URL, checksum, retrieval
time, and package version in their `ucdp_source` attribute.

Most analytical helpers also work with ordinary data frames. This makes
it possible to inspect a prepared subset without another download:

``` r

library(ucdpR)

events <- data.frame(
  id = 1:3,
  year = c(2020, 2021, 2021),
  where_prec = c(1, 2, 6),
  date_prec = c(1, 3, 5),
  latitude = c(50, 51, 52),
  longitude = c(10, 11, 12)
)

ucdp_schema(events)
#> # A tibble: 6 × 9
#>   variable   class   storage_type n_missing pct_missing n_unique minimum maximum
#>   <chr>      <chr>   <chr>            <int>       <dbl>    <int> <chr>   <chr>  
#> 1 id         integer integer              0           0        3 1       3      
#> 2 year       numeric double               0           0        2 2020    2021   
#> 3 where_prec numeric double               0           0        3 1       6      
#> 4 date_prec  numeric double               0           0        3 1       5      
#> 5 latitude   numeric double               0           0        3 50      52     
#> 6 longitude  numeric double               0           0        3 10      12     
#> # ℹ 1 more variable: examples <chr>
ucdp_precision(events)
#> # A tibble: 6 × 6
#>   dimension variable    code label                                       n share
#>   <chr>     <chr>      <int> <chr>                                   <int> <dbl>
#> 1 spatial   where_prec     1 Exact location                              1 0.333
#> 2 spatial   where_prec     2 Within approximately 25 km                  1 0.333
#> 3 spatial   where_prec     6 Country only                                1 0.333
#> 4 temporal  date_prec      1 Exact date                                  1 0.333
#> 5 temporal  date_prec      3 Week known                                  1 0.333
#> 6 temporal  date_prec      5 More than one month but less than one …     1 0.333
ucdp_filter_precision(events, where_prec = 1:2, date_prec = 1:3)
#>   id year where_prec date_prec latitude longitude
#> 1  1 2020          1         1       50        10
#> 2  2 2021          2         3       51        11
ucdp_aggregate(events, unit = "conflict-year", id = "id",
               include_fatalities = FALSE)
#> # A tibble: 3 × 3
#>      id  year n_events
#>   <int> <int>    <int>
#> 1     1  2020        1
#> 2     2  2021        1
#> 3     3  2021        1
```

Four focused vignettes provide the detailed workflows:

- [`vignette("accessing-and-versioning", package = "ucdpR")`](https://christianoswald.github.io/ucdpR/articles/accessing-and-versioning.md)
  explains catalog discovery, exact releases, downloads, imports, and
  update checks.
- [`vignette("spatial-workflows", package = "ucdpR")`](https://christianoswald.github.io/ucdpR/articles/spatial-workflows.md)
  covers precision-aware conversion to `sf` and preparation for
  downstream spatial joins.
- [`vignette("uncertainty-and-revisions", package = "ucdpR")`](https://christianoswald.github.io/ucdpR/articles/uncertainty-and-revisions.md)
  treats precision and retrospective revisions as observable dimensions
  of uncertainty.
- [`vignette("reproducible-research", package = "ucdpR")`](https://christianoswald.github.io/ucdpR/articles/reproducible-research.md)
  combines metadata, schemas, validation, codebooks, version histories,
  and replication files.

`ucdpR` is an independent community client and does not redistribute
UCDP data. Consult UCDP’s documentation and citation guidance for every
dataset and report the exact data version used in published work.
