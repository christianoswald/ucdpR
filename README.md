# ucdpR

<!-- badges: start -->
[![R-CMD-check](https://github.com/christianoswald/ucdpR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/christianoswald/ucdpR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/christianoswald/ucdpR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/christianoswald/ucdpR)
<!-- badges: end -->

`ucdpR` discovers, downloads, and imports datasets from the official [Uppsala
Conflict Data Program download center](https://ucdp.uu.se/downloads/). Because
the catalog is discovered at run time, new UCDP releases generally do not
require a package update.

## Installation

```r
# install.packages("ucdpR") # after CRAN release
# pak::pak("christianoswald/ucdpR")
```

## Quick start

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

## Scope and attribution

This package is an independent community client. It is not affiliated with or
endorsed by UCDP or Uppsala University, and it does not redistribute UCDP data.
Data remain subject to UCDP's documentation, citation guidance, and terms.

