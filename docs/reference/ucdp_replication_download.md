# Download files from the UCDP replication archive

Download files from the UCDP replication archive

## Usage

``` r
ucdp_replication_download(
  dataset,
  version = NULL,
  year = NULL,
  type = "data",
  query = NULL,
  variant = NULL,
  download_all = FALSE,
  dest_dir = "replication",
  overwrite = FALSE,
  quiet = FALSE,
  catalog = NULL
)
```

## Arguments

- dataset:

  Dataset name, alias, or regular expression.

- version:

  Optional exact dataset version.

- year:

  Optional publication year or years.

- type:

  File type to select. Defaults to frozen data files.

- query:

  Optional additional regular expression matched by
  [`ucdp_replication_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_replication_catalog.md).

- variant:

  Optional regular expression matched against artifact titles.

- download_all:

  Download every match? Otherwise ambiguous requests fail.

- dest_dir:

  Destination directory.

- overwrite:

  Replace existing files?

- quiet:

  Suppress messages?

- catalog:

  Optional pre-fetched replication catalog.

## Value

A normalized character vector of downloaded paths, invisibly, with
catalog records, checksums, retrieval time, and package version
attached.

## Examples

``` r
if (FALSE) { # \dontrun{
ucdp_replication_download("ged", version = "25.1")
} # }
```
