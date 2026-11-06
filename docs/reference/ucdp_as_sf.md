# Convert georeferenced UCDP data to an sf object

`ucdp_as_sf()` recognizes common UCDP coordinate columns and converts
them to point geometry. The original `ucdp_source` provenance attribute
is retained, making the result suitable for later spatial joins,
including workflows built around the released `priogrid` package or a
future `priogridR` package.

## Usage

``` r
ucdp_as_sf(
  data,
  longitude = NULL,
  latitude = NULL,
  crs = 4326,
  remove = FALSE,
  missing = c("keep", "drop", "error")
)
```

## Arguments

- data:

  A data frame containing coordinates, or an existing `sf` object.

- longitude, latitude:

  Coordinate column names. When omitted, common UCDP names are detected
  automatically.

- crs:

  Coordinate reference system passed to
  [`sf::st_as_sf()`](https://r-spatial.github.io/sf/reference/st_as_sf.html).
  UCDP GED coordinates use EPSG 4326.

- remove:

  Remove the source coordinate columns?

- missing:

  How to handle missing coordinates: retain them as empty geometries,
  drop their rows, or raise an error.

## Value

An `sf` object with point geometry.

## Examples

``` r
events <- data.frame(
  id = 1:3, longitude = c(10, 20, NA), latitude = c(50, 60, NA)
)
if (requireNamespace("sf", quietly = TRUE)) {
  events_sf <- ucdp_as_sf(events, missing = "drop")
  sf::st_crs(events_sf)
}
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
```
