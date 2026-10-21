# List available releases of a UCDP dataset

List available releases of a UCDP dataset

## Usage

``` r
ucdp_versions(
  dataset,
  format = NULL,
  include_documentation = FALSE,
  quiet = FALSE,
  catalog = NULL
)
```

## Arguments

- dataset:

  Dataset name, alias, or regular expression.

- format:

  Optional format to retain, such as `"csv"` or `"xlsx"`.

- include_documentation:

  Include codebooks and documentation?

- quiet:

  Suppress catalog messages?

- catalog:

  Optional catalog containing historical releases. When omitted,
  [`ucdp_catalog()`](https://christianoswald.github.io/ucdpR/reference/ucdp_catalog.md)
  is called with `include_historical = TRUE`.

## Value

A catalog tibble sorted from newer to older releases where possible.

## Examples

``` r
if (FALSE) { # \dontrun{
ucdp_versions("ged", format = "csv")
ucdp_versions("candidate", format = "csv")
} # }
```
