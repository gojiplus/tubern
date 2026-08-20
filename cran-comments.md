This is a minor release. It moves the HTTP layer from httr to httr2 and
renames four functions, both of which are breaking for users; the details
are below and in NEWS.md.

## Test environments

* local macOS (Tahoe 26.3.1), R 4.5.2
* GitHub Actions: ubuntu (devel, release, oldrel-1), macOS, windows
* win-builder (devel, release)

## R CMD check results
There were no ERRORs, WARNINGs or NOTEs.

## Summary of changes

* The package now uses httr2 throughout, authentication included, and no
  longer depends on httr. Tokens saved by earlier versions are httr
  `Token2.0` objects, which httr2 cannot read, so users must run `yt_oauth()`
  once more. `yt_oauth()` detects an old token and says so rather than
  failing later with a missing-field error.

* The token cache moved to `.tubern-oauth`. `.httr-oauth` is httr's shared
  cache, read by every httr-based package in the same working directory, so
  writing an httr2 token there would break their authentication;
  `yt_oauth()` now refuses to overwrite a file holding an httr cache.

* Four functions were renamed for consistency with the rest of the package:
  `add_groups()` to `add_group()`, `yt_to_dataframe()` to
  `yt_as_data_frame()`, `yt_to_tibble()` to `yt_as_tibble()`, and
  `diagnose_tubern()` to `yt_diagnose()`. The old names still work and warn
  once per session.

* An unrecognised metric, dimension or filter now warns and sends the request
  rather than aborting it. The local registries are transcribed by hand from
  Google's prose documentation, which enumerates nothing machine-readable, so
  refusing a name absent from a stale snapshot blocked requests the API would
  have answered. Names known to be wrong remain hard errors.

## Reverse dependencies
`devtools::revdep()` reports no reverse dependencies.
