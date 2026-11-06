# Download an official UCDP codebook

`ucdp_codebook()` locates documentation listed with a dataset in UCDP's
official download catalog. When an exact historical version is
requested, the function returns only documentation explicitly associated
with that version; it never silently substitutes the current codebook.

## Usage

``` r
ucdp_codebook(
  dataset,
  version = NULL,
  variant = NULL,
  dest_dir = ".",
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

- variant:

  Optional regular expression used to distinguish documentation
  variants.

- dest_dir:

  Destination directory.

- overwrite:

  Replace an existing file?

- open:

  Open the downloaded codebook with the system viewer?

- quiet:

  Suppress catalog and download messages?

- catalog:

  Optional catalog created with
  `ucdp_catalog(include_documentation = TRUE)`.

## Value

The normalized path to the downloaded codebook, invisibly. The path
carries the selected catalog record, version, checksum, retrieval time,
and package version as attributes.

## Examples

``` r
if (FALSE) { # \dontrun{
path <- ucdp_codebook("ged", dest_dir = "documentation")
ucdp_codebook("brd", variant = "dyadic", open = TRUE)
} # }
```
