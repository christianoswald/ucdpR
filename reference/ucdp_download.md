# Download an official UCDP data file

Download an official UCDP data file

## Usage

``` r
ucdp_download(
  dataset,
  format = "csv",
  variant = NULL,
  version = NULL,
  dest_dir = ".",
  overwrite = FALSE,
  include_historical = !is.null(version),
  quiet = FALSE,
  catalog = NULL
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

## Value

The normalized path to the downloaded file, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- ucdp_download("ged", format = "csv", dest_dir = tempdir())
} # }
```
