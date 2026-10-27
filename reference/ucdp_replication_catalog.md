# List publication-specific UCDP replication files

`ucdp_replication_catalog()` reads UCDP's official replication archive,
which contains frozen datasets and related materials used in
UCDP-authored publications.

## Usage

``` r
ucdp_replication_catalog(query = NULL, year = NULL, type = NULL, quiet = FALSE)
```

## Arguments

- query:

  Optional case-insensitive regular expression matched against
  publication, dataset, title, version, and file type.

- year:

  Optional publication year or years.

- type:

  Optional file types such as `"data"`, `"codebook"`,
  `"version_history"`, `"appendix"`, or `"other"`.

- quiet:

  Suppress the status message?

## Value

A tibble with one row per downloadable replication artifact.

## Examples

``` r
if (FALSE) { # \dontrun{
catalog <- ucdp_replication_catalog(year = 2025)
ucdp_replication_catalog("Georeferenced", type = "data")
} # }
```
