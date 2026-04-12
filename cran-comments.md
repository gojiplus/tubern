## Test environments

* local macOS (aarch64-apple-darwin20), R 4.5.2
* GitHub Actions: ubuntu-latest, macOS-latest, windows-latest (R 4.3, 4.4)
* R-hub: linux, windows, macos
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

The NOTE is about "OAuth" being flagged as possibly misspelled in DESCRIPTION.
This is a false positive - OAuth is a standard authentication protocol name.

## Downstream dependencies

None known.

## Notes

This is a major update (v0.5.0) with:

- Added checkmate and rlang dependencies for modern validation/error handling
- Improved test coverage with mock-based testing (no API tokens needed in CI)
- New helper functions for common report types
- Enhanced error messages with suggestions
- Retry logic for transient API failures
