# ucdpR 0.2.2

* Removed a non-ASCII character from executable R code.
* Qualified `utils::head()` for clean static code analysis.
* Excluded development-only files from the CRAN source archive.

# ucdpR 0.2.1

* Fixed live catalog discovery after UCDP served dataset headings at a
  different HTML level than the rendered page suggested.
* Fixed the multiple-match diagnostic so it includes a stable headline and
  can be tested reliably.

# ucdpR 0.2.0

* Historical releases are now discovered from UCDP's dedicated archive.
* Added `ucdp_versions()` to inspect downloadable versions before selection.
* `version` now supports annual and monthly Candidate release identifiers.
* Downloads and imported objects retain source, version, and checksum metadata.
* Improved detection of historical dyadic and conflict-level variants.

# ucdpR 0.1.0

* Initial release.
* Added live catalog discovery, search, download, import, citation, and update
  checking helpers.

