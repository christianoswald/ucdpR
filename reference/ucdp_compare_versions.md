# Compare two releases of a UCDP dataset

`ucdp_compare_versions()` identifies observations and values that were
added, removed, or revised between two UCDP releases. It can download
both releases or compare data frames that have already been imported.

## Usage

``` r
ucdp_compare_versions(
  dataset,
  old_version,
  new_version,
  variant = NULL,
  format = "csv",
  key = NULL,
  columns = NULL,
  ignore = "version",
  tolerance = sqrt(.Machine$double.eps),
  detail = c("rows", "cells", "summary"),
  old_data = NULL,
  new_data = NULL,
  quiet = FALSE,
  ...
)
```

## Arguments

- dataset:

  Dataset name or alias accepted by
  [`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md).

- old_version, new_version:

  Exact release identifiers.

- variant:

  Optional dataset variant, such as `"dyadic"`.

- format:

  Download format. CSV is recommended for stable comparisons.

- key:

  Character vector of columns that uniquely identify observations. When
  `NULL`, a key is inferred and verified for uniqueness in both data
  sets.

- columns:

  Columns whose values should be compared. The default compares all
  columns shared by the releases except key and ignored columns.

- ignore:

  Columns to exclude from value comparisons. The release-level `version`
  column is ignored by default because it necessarily differs.

- tolerance:

  Relative tolerance for comparisons between numeric values.

- detail:

  Return `"rows"` (the default), cell-level changes with `"cells"`, or
  only summaries with `"summary"`.

- old_data, new_data:

  Optional preloaded data frames. Supply both or neither. This is useful
  when releases have already been downloaded.

- quiet:

  Suppress download messages?

- ...:

  Additional arguments passed to
  [`ucdp_get()`](https://christianoswald.github.io/ucdpR/reference/ucdp_get.md)
  for both releases.

## Value

An object of class `ucdp_version_comparison`. Its components include
`overview`, `variables`, `added`, `removed`, `modified`, `cell_changes`,
and `metadata`.

## Examples

``` r
old <- data.frame(id = 1:3, deaths = c(1, 2, 3), version = "1.0")
new <- data.frame(id = 2:4, deaths = c(2, 4, 1), version = "2.0")
comparison <- ucdp_compare_versions(
  "ged", "1.0", "2.0", key = "id",
  old_data = old, new_data = new
)
comparison$overview
#> # A tibble: 1 × 7
#>   old_rows new_rows matched added removed modified unchanged
#>      <int>    <int>   <int> <int>   <int>    <int>     <int>
#> 1        3        3       2     1       1        1         1

if (FALSE) { # \dontrun{
comparison <- ucdp_compare_versions("ged", "24.1", "25.1")
comparison$modified
} # }
```
