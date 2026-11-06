# Download an official UCDP version history

Download an official UCDP version history

## Usage

``` r
ucdp_version_history(
  dataset,
  version = NULL,
  dest_dir = "documentation",
  overwrite = FALSE,
  open = FALSE,
  quiet = FALSE,
  catalog = NULL
)
```

## Arguments

- dataset:

  Dataset name or alias.

- version:

  Optional exact release identifier.

- dest_dir:

  Destination directory.

- overwrite:

  Replace an existing file?

- open:

  Open the downloaded file with the system viewer?

- quiet:

  Suppress messages?

- catalog:

  Optional pre-fetched version-history catalog, primarily for
  reproducible or offline use.

## Value

The normalized downloaded path, invisibly, with provenance attributes.

## Examples

``` r
if (FALSE) ucdp_version_history("prio", version = "25.1") # \dontrun{}
```
