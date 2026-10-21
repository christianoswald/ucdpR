# Search the UCDP catalog

Search the UCDP catalog

## Usage

``` r
ucdp_search(query, catalog = NULL, ...)
```

## Arguments

- query:

  A case-insensitive regular expression matched against dataset,
  variant, version, and section names.

- catalog:

  A catalog returned by
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md).
  If omitted, the current catalog is downloaded.

- ...:

  Passed to
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md)
  when `catalog` is omitted.

## Value

A filtered catalog tibble.

## Examples

``` r
if (FALSE) ucdp_search("georeferenced|GED") # \dontrun{}
```
