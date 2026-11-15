# Spatial and precision-aware workflows

Georeferenced conflict events differ in how precisely their locations
and dates are known. Spatial conversion should therefore be paired with
an explicit precision decision rather than treated as a purely technical
step.

``` r

library(ucdpR)

events <- data.frame(
  id = 1:6,
  country = c("A", "A", "A", "B", "B", "B"),
  year = c(2020, 2020, 2021, 2020, 2021, 2021),
  longitude = c(10.0, 10.4, 11.0, 20.0, 20.5, NA),
  latitude = c(50.0, 50.2, 51.0, 40.0, 40.4, NA),
  where_prec = c(1, 2, 4, 1, 3, 6),
  date_prec = c(1, 3, 4, 2, 5, 1)
)
```

## Describe precision before filtering

`where_prec` describes spatial precision and `date_prec` temporal
precision. The summary reports counts and within-group shares while
retaining the numeric codes used by UCDP.

``` r

ucdp_precision(events)
#> # A tibble: 10 × 6
#>    dimension variable    code label                                      n share
#>    <chr>     <chr>      <int> <chr>                                  <int> <dbl>
#>  1 spatial   where_prec     1 Exact location                             2 0.333
#>  2 spatial   where_prec     2 Within approximately 25 km                 1 0.167
#>  3 spatial   where_prec     3 Second-order administrative division       1 0.167
#>  4 spatial   where_prec     4 First-order administrative division        1 0.167
#>  5 spatial   where_prec     6 Country only                               1 0.167
#>  6 temporal  date_prec      1 Exact date                                 2 0.333
#>  7 temporal  date_prec      2 Two-to-six-day range                       1 0.167
#>  8 temporal  date_prec      3 Week known                                 1 0.167
#>  9 temporal  date_prec      4 Eight-to-thirty-day range or month kn…     1 0.167
#> 10 temporal  date_prec      5 More than one month but less than one…     1 0.167
ucdp_precision(events, by = "country")
#> # A tibble: 12 × 7
#>    country dimension variable    code label                              n share
#>    <chr>   <chr>     <chr>      <int> <chr>                          <int> <dbl>
#>  1 A       spatial   where_prec     1 Exact location                     1 0.333
#>  2 A       spatial   where_prec     2 Within approximately 25 km         1 0.333
#>  3 A       spatial   where_prec     4 First-order administrative di…     1 0.333
#>  4 B       spatial   where_prec     1 Exact location                     1 0.333
#>  5 B       spatial   where_prec     3 Second-order administrative d…     1 0.333
#>  6 B       spatial   where_prec     6 Country only                       1 0.333
#>  7 A       temporal  date_prec      1 Exact date                         1 0.333
#>  8 A       temporal  date_prec      3 Week known                         1 0.333
#>  9 A       temporal  date_prec      4 Eight-to-thirty-day range or …     1 0.333
#> 10 B       temporal  date_prec      1 Exact date                         1 0.333
#> 11 B       temporal  date_prec      2 Two-to-six-day range               1 0.333
#> 12 B       temporal  date_prec      5 More than one month but less …     1 0.333
ucdp_precision(events, by = "year", include_missing = FALSE)
#> # A tibble: 11 × 7
#>     year dimension variable    code label                                n share
#>    <dbl> <chr>     <chr>      <int> <chr>                            <int> <dbl>
#>  1  2020 spatial   where_prec     1 Exact location                       2 0.667
#>  2  2020 spatial   where_prec     2 Within approximately 25 km           1 0.333
#>  3  2021 spatial   where_prec     3 Second-order administrative div…     1 0.333
#>  4  2021 spatial   where_prec     4 First-order administrative divi…     1 0.333
#>  5  2021 spatial   where_prec     6 Country only                         1 0.333
#>  6  2020 temporal  date_prec      1 Exact date                           1 0.333
#>  7  2020 temporal  date_prec      2 Two-to-six-day range                 1 0.333
#>  8  2020 temporal  date_prec      3 Week known                           1 0.333
#>  9  2021 temporal  date_prec      1 Exact date                           1 0.333
#> 10  2021 temporal  date_prec      4 Eight-to-thirty-day range or mo…     1 0.333
#> 11  2021 temporal  date_prec      5 More than one month but less th…     1 0.333
```

## Make the analytical threshold explicit

Filtering by named arguments keeps the decision visible in the script.
Here, only events with relatively precise locations and dates are
retained.

``` r

precise_events <- ucdp_filter_precision(
  events,
  where_prec = 1:2,
  date_prec = 1:3,
  missing = "drop"
)
precise_events
#>   id country year longitude latitude where_prec date_prec
#> 1  1       A 2020      10.0     50.0          1         1
#> 2  2       A 2020      10.4     50.2          2         3
#> 4  4       B 2020      20.0     40.0          1         2
```

There is no universally correct cutoff. The defensible choice depends on
the spatial resolution, research design, and consequences of assigning
an imprecise event to one spatial unit. Sensitivity analyses can repeat
the same workflow under alternative thresholds.

## Convert coordinates to `sf`

[`ucdp_as_sf()`](https://christianoswald.github.io/ucdpR/reference/ucdp_as_sf.md)
recognizes common longitude and latitude names, uses EPSG 4326 by
default, and retains the `ucdp_source` provenance attribute when
present. The chunk is evaluated only when the optional `sf` package is
installed.

``` r

events_sf <- ucdp_as_sf(precise_events)
events_sf
#> Simple feature collection with 3 features and 7 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 10 ymin: 40 xmax: 20 ymax: 50.2
#> Geodetic CRS:  WGS 84
#>   id country year longitude latitude where_prec date_prec          geometry
#> 1  1       A 2020      10.0     50.0          1         1     POINT (10 50)
#> 2  2       A 2020      10.4     50.2          2         3 POINT (10.4 50.2)
#> 4  4       B 2020      20.0     40.0          1         2     POINT (20 40)
sf::st_crs(events_sf)
#> Coordinate Reference System:
#>   User input: EPSG:4326 
#>   wkt:
#> GEOGCRS["WGS 84",
#>     ENSEMBLE["World Geodetic System 1984 ensemble",
#>         MEMBER["World Geodetic System 1984 (Transit)"],
#>         MEMBER["World Geodetic System 1984 (G730)"],
#>         MEMBER["World Geodetic System 1984 (G873)"],
#>         MEMBER["World Geodetic System 1984 (G1150)"],
#>         MEMBER["World Geodetic System 1984 (G1674)"],
#>         MEMBER["World Geodetic System 1984 (G1762)"],
#>         MEMBER["World Geodetic System 1984 (G2139)"],
#>         MEMBER["World Geodetic System 1984 (G2296)"],
#>         ELLIPSOID["WGS 84",6378137,298.257223563,
#>             LENGTHUNIT["metre",1]],
#>         ENSEMBLEACCURACY[2.0]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
#>     CS[ellipsoidal,2],
#>         AXIS["geodetic latitude (Lat)",north,
#>             ORDER[1],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         AXIS["geodetic longitude (Lon)",east,
#>             ORDER[2],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>     USAGE[
#>         SCOPE["Horizontal component of 3D system."],
#>         AREA["World."],
#>         BBOX[-90,-180,90,180]],
#>     ID["EPSG",4326]]
sf::st_coordinates(events_sf)
#>         X    Y
#> [1,] 10.0 50.0
#> [2,] 10.4 50.2
#> [3,] 20.0 40.0
```

Missing coordinates can be retained as empty geometries, dropped, or
treated as an error:

``` r

ucdp_as_sf(events, missing = "keep")
#> Simple feature collection with 6 features and 7 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 10 ymin: 40 xmax: 20.5 ymax: 51
#> Geodetic CRS:  WGS 84
#>   id country year longitude latitude where_prec date_prec          geometry
#> 1  1       A 2020      10.0     50.0          1         1     POINT (10 50)
#> 2  2       A 2020      10.4     50.2          2         3 POINT (10.4 50.2)
#> 3  3       A 2021      11.0     51.0          4         4     POINT (11 51)
#> 4  4       B 2020      20.0     40.0          1         2     POINT (20 40)
#> 5  5       B 2021      20.5     40.4          3         5 POINT (20.5 40.4)
#> 6  6       B 2021        NA       NA          6         1       POINT EMPTY
ucdp_as_sf(events, missing = "drop")
#> Simple feature collection with 5 features and 7 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 10 ymin: 40 xmax: 20.5 ymax: 51
#> Geodetic CRS:  WGS 84
#>   id country year longitude latitude where_prec date_prec          geometry
#> 1  1       A 2020      10.0     50.0          1         1     POINT (10 50)
#> 2  2       A 2020      10.4     50.2          2         3 POINT (10.4 50.2)
#> 3  3       A 2021      11.0     51.0          4         4     POINT (11 51)
#> 4  4       B 2020      20.0     40.0          1         2     POINT (20 40)
#> 5  5       B 2021      20.5     40.4          3         5 POINT (20.5 40.4)
```

## Assign events to PRIO-GRID cells

The resulting object is an ordinary `sf` data frame and can be
transformed, intersected, or joined using standard spatial operations.
For the released `priogrid` package,
[`ucdp_to_priogrid()`](https://christianoswald.github.io/ucdpR/reference/ucdp_to_priogrid.md)
extracts the `pgid` from the grid created under its current
configuration. The packages are optional, so this installation-dependent
example is not evaluated in the vignette.

``` r

ged <- ucdp_get("ged", version = "25.1")
ged_precise <- ucdp_filter_precision(ged, where_prec = 1:2)
ged_pg <- ucdp_to_priogrid(ged_precise)
grid_year <- ucdp_aggregate(ged_pg, unit = "grid-year", id = "pgid")
```

A one-layer `SpatRaster` may be supplied through `grid` to freeze the
exact grid definition. The conventional `pgid` output is designed to
remain usable with the planned `priogridR` package as well.
