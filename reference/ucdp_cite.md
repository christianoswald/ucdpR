# Retrieve citation guidance for a UCDP dataset

This function extracts the citation block displayed below a dataset on
the official UCDP download page. Always report the dataset version in
your own work and consult the downloaded codebook for dataset-specific
guidance.

## Usage

``` r
ucdp_cite(dataset, quiet = FALSE)
```

## Arguments

- dataset:

  Dataset name or alias.

- quiet:

  Suppress status messages?

## Value

A character vector containing the citation guidance.

## Examples

``` r
if (FALSE) ucdp_cite("ged") # \dontrun{}
```
