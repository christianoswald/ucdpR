# Check whether a downloaded UCDP file has a newer catalog version

Check whether a downloaded UCDP file has a newer catalog version

## Usage

``` r
ucdp_update_available(dataset, version, catalog = NULL)
```

## Arguments

- dataset:

  Dataset name or alias.

- version:

  The version used in an analysis.

- catalog:

  Optional current catalog.

## Value

A one-row tibble with the supplied and current versions and a logical
`update_available` value.
