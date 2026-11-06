# Assign UCDP events to PRIO-GRID cells

Converts event coordinates to points and extracts the `pgid` from the
grid produced by
[`priogrid::prio_blank_grid()`](http://prio-data.github.io/priogrid/reference/prio_blank_grid.md).
A pre-built `SpatRaster` can be supplied to freeze the exact grid
configuration or test the workflow offline. The function targets the
released `priogrid` package; the simple `pgid` output is also intended
as a stable bridge for future grid tooling.

## Usage

``` r
ucdp_to_priogrid(
  data,
  longitude = NULL,
  latitude = NULL,
  grid = NULL,
  config = NULL,
  pgid = "pgid",
  missing = c("keep", "drop", "error")
)
```

## Arguments

- data:

  A data frame with coordinates or an `sf` point object.

- longitude, latitude:

  Optional coordinate columns passed to
  [`ucdp_as_sf()`](https://christianoswald.github.io/ucdpR/reference/ucdp_as_sf.md).

- grid:

  Optional `terra` `SpatRaster` whose cell values are PRIO-GRID
  identifiers. If omitted,
  [`priogrid::prio_blank_grid()`](http://prio-data.github.io/priogrid/reference/prio_blank_grid.md)
  is used.

- config:

  Optional `priogrid` configuration passed to `prio_blank_grid()`.
  Ignored when `grid` is supplied.

- pgid:

  Name of the output identifier column.

- missing:

  Handling of missing coordinates or cells outside the grid.

## Value

A tibble (or `sf` object when the input is `sf`) with a PRIO-GRID
identifier and preserved UCDP provenance.

## Examples

``` r
events <- data.frame(id = 1:2, longitude = c(10, 20), latitude = c(50, 60))
# Requires the optional priogrid, terra, and sf packages:
if (FALSE) ucdp_to_priogrid(events)
```
