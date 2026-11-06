# List files in the official UCDP download catalog

`ucdp_catalog()` reads the official download page each time it is
called, so newly released datasets can be discovered without a package
update.

## Usage

``` r
ucdp_catalog(
  include_documentation = FALSE,
  include_historical = FALSE,
  quiet = FALSE
)
```

## Arguments

- include_documentation:

  Include codebooks and other documentation?

- include_historical:

  Also inspect UCDP's historical-download page? This adds earlier annual
  releases and archived monthly Candidate releases.

- quiet:

  Suppress status messages?

## Value

A tibble with one row per downloadable file.

## Examples

``` r
if (FALSE) { # \dontrun{
# This function reads the live UCDP website.
catalog <- ucdp_catalog()
head(catalog)
ucdp_catalog(include_historical = TRUE)
} # }
```
