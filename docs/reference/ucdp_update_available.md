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

## Examples

``` r
catalog <- tibble::tibble(
  dataset = "UCDP Georeferenced Event Dataset (GED)", version = "25.1",
  variant = NA_character_, section = "Disaggregated Event Datasets",
  format = "csv", url = "https://example.org/ged.csv",
  file_name = "ged.csv", source = "current"
)
ucdp_update_available("ged", version = "24.1", catalog = catalog)
#> # A tibble: 1 × 4
#>   dataset installed_version current_version update_available
#>   <chr>   <chr>             <chr>           <lgl>           
#> 1 ged     24.1              25.1            TRUE            
```
