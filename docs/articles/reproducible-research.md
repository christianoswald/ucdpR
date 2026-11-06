# Reproducible research with UCDP data

A reproducible UCDP workflow records the exact release, inspects the
imported structure, checks analytical assumptions, and retains the
corresponding documentation. `ucdpR` keeps these tasks separate so that
each decision remains visible.

``` r

library(ucdpR)

conflicts <- data.frame(
  conflict_id = c(1, 2, 3),
  year = c(2020, 2021, 2021),
  location = c("A", "B", "C"),
  low = c(0, 2, 1),
  best = c(1, 3, 2),
  high = c(2, 4, 3),
  latitude = c(10, 20, 30),
  longitude = c(40, 50, 60)
)
```

## Describe the object and its coverage

[`ucdp_metadata()`](https://christianoswald.github.io/ucdpR/reference/ucdp_metadata.md)
gives a compact record of dimensions and available temporal or
coordinate coverage. Imported UCDP objects additionally report their
source record, checksum, retrieval time, and package version.

``` r

ucdp_metadata(conflicts, dataset = "Synthetic conflict data")
#> # A tibble: 1 × 20
#>   dataset             version variant format file_name source_url catalog_source
#>   <chr>               <chr>   <chr>   <chr>  <chr>     <chr>      <chr>         
#> 1 Synthetic conflict… NA      NA      NA     NA        NA         NA            
#> # ℹ 13 more variables: retrieved_at <chr>, md5 <chr>, ucdpR_version <chr>,
#> #   n_rows <int>, n_columns <int>, year_min <int>, year_max <int>,
#> #   date_min <chr>, date_max <chr>, latitude_min <dbl>, latitude_max <dbl>,
#> #   longitude_min <dbl>, longitude_max <dbl>
```

[`ucdp_schema()`](https://christianoswald.github.io/ucdpR/reference/ucdp_schema.md)
works at the variable level and is useful before joins, transformations,
or model preparation.

``` r

schema <- ucdp_schema(conflicts)
schema[c("variable", "class", "n_missing", "n_unique", "minimum", "maximum")]
#> # A tibble: 8 × 6
#>   variable    class     n_missing n_unique minimum maximum
#>   <chr>       <chr>         <int>    <int> <chr>   <chr>  
#> 1 conflict_id numeric           0        3 1       3      
#> 2 year        numeric           0        2 2020    2021   
#> 3 location    character         0        3 NA      NA     
#> 4 low         numeric           0        3 0       2      
#> 5 best        numeric           0        3 1       3      
#> 6 high        numeric           0        3 2       4      
#> 7 latitude    numeric           0        3 10      30     
#> 8 longitude   numeric           0        3 40      60
```

## Validate assumptions without altering data

Validation checks are applied only when their required variables are
present. The result separates a compact summary from record-level
issues.

``` r

validation <- ucdp_validate(conflicts, key = "conflict_id")
validation$valid
#> [1] TRUE
validation$summary
#> # A tibble: 5 × 3
#>   check       status  n_issues
#>   <chr>       <chr>      <int>
#> 1 keys        pass           0
#> 2 dates       skipped        0
#> 3 fatalities  pass           0
#> 4 coordinates pass           0
#> 5 codes       skipped        0
validation$issues
#> # A tibble: 0 × 6
#> # ℹ 6 variables: check <chr>, severity <chr>, row <int>, column <chr>,
#> #   value <chr>, message <chr>
```

Warnings identify observations for inspection; they do not establish
that UCDP made a coding error. With `strict = TRUE`, warnings also make
the overall validation result invalid, which can be useful in automated
pipelines.

## Aggregate events and retain fatality uncertainty

Fatality estimates should be aggregated as a low, best, and high triplet
rather than reducing every observation to its best estimate alone.

``` r

ucdp_fatalities(conflicts, by = "year")
#> # A tibble: 2 × 7
#>    year n_observations n_complete n_missing fatalities_low fatalities_best
#>   <dbl>          <int>      <int>     <int>          <dbl>           <dbl>
#> 1  2020              1          1         0              0               1
#> 2  2021              2          2         0              3               5
#> # ℹ 1 more variable: fatalities_high <dbl>

conflict_year <- ucdp_aggregate(
  conflicts,
  unit = "conflict-year"
)
conflict_year
#> # A tibble: 3 × 8
#>   conflict_id  year n_events n_fatality_complete n_fatality_missing
#>         <dbl> <int>    <int>               <int>              <int>
#> 1           1  2020        1                   1                  0
#> 2           2  2021        1                   1                  0
#> 3           3  2021        1                   1                  0
#> # ℹ 3 more variables: fatalities_low <dbl>, fatalities_best <dbl>,
#> #   fatalities_high <dbl>
```

[`ucdp_aggregate()`](https://christianoswald.github.io/ucdpR/reference/ucdp_aggregate.md)
also supports country, PRIO-GRID, and dyad units with yearly or monthly
periods. Common entity and fatality columns are detected, while `id`,
`date`, `low`, `best`, and `high` provide explicit overrides.

## Construct complete panels transparently

``` r

panel_events <- data.frame(
  conflict_id = c(1, 1, 2),
  year = c(2020, 2022, 2021),
  low = c(0, 1, 2), best = c(1, 2, 3), high = c(2, 3, 4)
)

panel <- ucdp_panel(
  panel_events,
  unit = "conflict-year",
  start = 2020,
  end = 2022,
  fill = "zero"
)
panel[c("conflict_id", "year", "n_events", ".ucdp_observed", ".ucdp_fill")]
#> # A tibble: 6 × 5
#>   conflict_id  year n_events .ucdp_observed .ucdp_fill 
#>         <dbl> <int>    <int> <lgl>          <chr>      
#> 1           1  2020        1 TRUE           observed   
#> 2           1  2021        0 FALSE          zero_filled
#> 3           1  2022        1 TRUE           observed   
#> 4           2  2020        0 FALSE          zero_filled
#> 5           2  2021        1 TRUE           observed   
#> 6           2  2022        0 FALSE          zero_filled
```

Rows introduced to complete the panel remain identifiable. A zero-filled
row does not prove that UCDP observed a true zero; it records the
analyst’s chosen completion rule. Use `fill = "missing"` when unobserved
combinations should remain missing, and supply `universe` when the panel
must include entities that never appear in the event data.

## Retain provenance with live data

``` r

prio <- ucdp_get("prio", version = "25.1", format = "csv")
ucdp_metadata(prio)
ucdp_schema(prio)
ucdp_validate(prio)
```

If the original source file should remain alongside the analysis, use
[`ucdp_download()`](https://christianoswald.github.io/ucdpR/reference/ucdp_download.md)
and store it in a project directory rather than relying on a temporary
import.

## Keep documentation with the release

Codebooks explain variables and coding rules; version histories explain
changes between releases; citation guidance records the attribution
requested by UCDP.

``` r

ucdp_codebook(
  "prio", version = "25.1", dest_dir = "documentation"
)
ucdp_version_history(
  "prio", version = "25.1", dest_dir = "documentation"
)
ucdp_cite("prio")
```

Exact historical documentation is returned only when UCDP explicitly
lists a matching artifact. The package does not silently substitute a
current codebook for an older release.

## Use publication-specific replication files

UCDP’s replication archive is distinct from its ordinary dataset
catalog. It contains frozen files associated with particular
publications.

``` r

replication <- ucdp_replication_catalog(
  query = "Georeferenced", year = 2025, type = "data"
)

paths <- ucdp_replication_download(
  "ged", version = "25.1", year = 2025,
  dest_dir = "replication"
)

attr(paths, "ucdp_records")
attr(paths, "md5")
```

## A practical project record

For each empirical analysis, retain at least:

1.  the dataset name, exact version, and variant;
2.  the original file or its source URL and checksum;
3.  the retrieval date and `ucdpR` version;
4.  the matching codebook and version history;
5.  validation output and explicit filtering decisions; and
6.  UCDP’s requested citation.

These records do not eliminate all sources of uncertainty, but they make
the analytical input reconstructable and revisions auditable.
