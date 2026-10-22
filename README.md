# ucdpR

<!-- badges: start -->
[![R-CMD-check](https://github.com/christianoswald/ucdpR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/christianoswald/ucdpR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/christianoswald/ucdpR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/christianoswald/ucdpR)
<!-- badges: end -->

`ucdpR` is a toolkit for reproducible research with data from the [Uppsala
Conflict Data Program](https://ucdp.uu.se/). It provides a consistent R
interface for finding, downloading, importing, documenting, and comparing UCDP
datasets. Downloading data is the foundation, but the package is designed to
grow around the wider tasks that applied researchers repeatedly encounter when
working with UCDP data.

The package currently helps researchers:

* discover available datasets without hard-coding download URLs;
* download or directly import current and historical releases;
* pin exact versions for reproducible research;
* preserve source URLs, versions, retrieval details, and file checksums;
* retrieve dataset citation guidance; and
* audit retrospective changes between two releases.

Because the catalog is read from the official download center at run time, new
UCDP releases generally do not require a package update. `ucdpR` does not bundle
or redistribute UCDP data.

## Installation

```r
# install.packages("ucdpR") # after CRAN release
# pak::pak("christianoswald/ucdpR")
```

## Find and import data

```r
library(ucdpR)

# See all current downloadable data files
catalog <- ucdp_catalog()

# Search without remembering exact titles
ucdp_search("georeferenced|candidate", catalog)

# Download a reproducible local copy
path <- ucdp_download("ged", format = "csv", dest_dir = "data-raw")

# Or download and import it directly
ged <- ucdp_get("ged", format = "csv")

# Inspect and download a frozen historical release
ucdp_versions("ged", format = "csv")
ged_24 <- ucdp_get("ged", version = "24.1", format = "csv")

# Monthly Candidate releases can be pinned in the same way
candidate <- ucdp_get("candidate", version = "25.0.12", format = "csv")

# Select a specific file when a dataset has multiple variants
brd <- ucdp_get("brd", variant = "dyadic", format = "csv")
```

For reproducible research, specify `version` explicitly and record the returned
filename, source metadata, and checksum. Imported objects retain these details
in their `ucdp_source` attribute. Cite the dataset as requested by UCDP and
avoid silently replacing frozen research data. `ucdp_cite("ged")` retrieves
the current citation guidance.

## Compare releases

UCDP datasets can be retrospectively revised. `ucdp_compare_versions()` turns
two official releases into a structured revision audit:

```r
comparison <- ucdp_compare_versions(
  "ged",
  old_version = "24.1",
  new_version = "25.1"
)

comparison$overview   # added, removed, modified, and unchanged rows
comparison$variables  # number of revisions by variable
comparison$added      # complete newly added observations
comparison$removed    # complete removed observations
comparison$modified   # keys and variables changed in matched observations
```

For cell-level old and new values, set `detail = "cells"`. For large releases
where only counts are required, use `detail = "summary"` to limit memory use.

## Package direction

Future convenience functions will build on the same principles: reproducible
inputs, explicit versions, transparent transformations, and outputs that fit
ordinary R workflows. The aim is to reduce recurring data-management work for
UCDP users while keeping analytical choices visible and under the researcher's
control.

## Scope and attribution

This package is an independent community client. It is not affiliated with or
endorsed by UCDP or Uppsala University, and it does not redistribute UCDP data.
Data remain subject to UCDP's documentation, citation guidance, and terms.

