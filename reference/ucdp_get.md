# Download and import a UCDP dataset

Download and import a UCDP dataset

## Usage

``` r
ucdp_get(
  dataset,
  format = "csv",
  variant = NULL,
  version = NULL,
  dest_dir = tempdir(),
  overwrite = TRUE,
  include_historical = !is.null(version),
  quiet = FALSE,
  catalog = NULL,
  ...,
  keep_file = FALSE
)
```

## Arguments

- dataset:

  Dataset name, alias, or regular expression. Use
  [`ucdp_search()`](https://christianoswald.github.io/ucdpR/reference/ucdp_search.md)
  to inspect matches. Common aliases include `ged`, `candidate`, `prio`,
  `dyadic`, `nonstate`, `onesided`, `brd`, and `actor`.

- format:

  Preferred format, including `"csv"`, `"xlsx"`, `"dta"`, `"rdata"`,
  `"sql"`, `"shapefile"`, `"geojson"`, or `"any"`.

- variant:

  Optional regular expression used to select among variants such as
  dyadic/conflict-level BRD files or onset datasets.

- version:

  Optional exact UCDP version, for example `"24.1"` or `"25.0.12"`.
  Supplying a version automatically searches the historical catalog. Use
  [`ucdp_versions()`](https://christianoswald.github.io/ucdpR/reference/ucdp_versions.md)
  to inspect downloadable releases.

- dest_dir:

  Destination directory. It is created when necessary.

- overwrite:

  Replace an existing file?

- include_historical:

  Search the historical-download page too?

- quiet:

  Suppress messages and download progress?

- catalog:

  Optional pre-fetched catalog, useful for repeated downloads.

- ...:

  Additional arguments passed to the relevant reader (`readr`, `readxl`,
  or `haven`).

- keep_file:

  Keep the downloaded file? The default stores it in a temporary
  directory and removes it after import.

## Value

An imported data object. CSV files return a tibble; Excel and Stata
files return the objects produced by `readxl` and `haven`.

## Examples

``` r
if (FALSE) { # \dontrun{
ged <- ucdp_get("ged", format = "csv")
} # }
```
