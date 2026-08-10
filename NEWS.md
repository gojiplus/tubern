# tubern (development version)

## Behaviour changes

* A metric, dimension or filter dimension that this package does not recognise
  now warns and is sent to the API, rather than aborting the request. The
  registries in `validation_helpers.R` are transcribed by hand from Google's
  prose documentation -- the discovery document types `metrics` and
  `dimensions` as plain strings and enumerates nothing -- so they are a
  snapshot, and YouTube adds names to the API without asking. Refusing a name
  missing from a stale snapshot blocked requests the API would have answered,
  with no way around it short of editing the package. The spelling suggestions
  are unchanged; they now appear in the warning.

  Names that are *known* to be wrong are still hard errors, because there the
  package can say what the mistake is: `videoThumbnailImpressions`,
  `videoThumbnailImpressionsClickRate` and `subscriberStatus` are bulk
  Reporting API spellings that `reports.query` does not accept, and the error
  now names the API they belong to.

* A 400 carrying "The query is not supported." now explains that the request's
  parts may each be valid while their combination is not, repeats the
  dimensions, metrics and filters that were sent, and links the report
  reference. YouTube Analytics is a fixed set of reports rather than a free
  combination of dimensions and metrics, and the API's own message does not
  say so -- this is the error `get_audience_demographics()` produced when it
  defaulted to `views` by `ageGroup`.

# tubern 0.5.1

## Bug fixes

* A relative `end_date` resolved to the *start* of its own window.
  `.parse_date_string()` maps a range name to the beginning of that range, and
  `end_date` was passed through it unchanged, so a value like `"last_month"`
  returned the first day of the period rather than the last and silently
  shortened every such report. Absolute `YYYY-MM-DD` input was always correct,
  which is why this was not obvious.

* Two revenue metrics used names the API had renamed: `adEarnings` and
  `impressionBasedCpm` are the pre-v2 spellings of `estimatedAdRevenue` and
  `cpm`, so requests carrying them did not return the intended columns.

* The retry helper called `force(expr)` inside its loop. `expr` is a promise, so
  forcing it again memoises the first result and a retry replayed a stale value
  rather than re-issuing the request. It also signalled "retry" by returning
  `NULL`, which was indistinguishable from a genuine `NULL` result. The caller's
  expression is now re-evaluated each attempt and the retry signal is a distinct
  sentinel.

* Only HTTP 200 counted as success, but `groups.delete` and `groupItems.delete`
  return 204 with an empty body, so a successful delete was handled as a
  failure. Any 2xx is now a success. The error path also called `$` on a body
  that comes back as `raw(0)` when empty, which is an error on an atomic vector;
  an empty error body now reports the status instead.

# tubern 0.5.0

## Modernization & Code Quality

* **NEW**: Added `checkmate` dependency for robust parameter validation
* **NEW**: Added `rlang` dependency for modern error handling with `abort()` and structured error classes
* **NEW**: Retry logic for transient API failures with exponential backoff
* **NEW**: Mock-based test suite that runs without API credentials
* **NEW**: Comprehensive test coverage for validation, error handling, and data transformation

## Major Usability Enhancements

* **NEW**: Pre-built report functions for common analytics tasks:
  - `get_channel_overview()` - Comprehensive channel performance metrics
  - `get_top_videos()` - Best performing videos with sorting
  - `get_audience_demographics()` - Age/gender audience breakdown  
  - `get_geographic_performance()` - Performance by country/region
  - `get_daily_performance()` - Time series data for trend analysis
  - `get_revenue_report()` - Monetization metrics (requires monetary scope)

* **NEW**: Smart date handling with relative dates:
  - Support for intuitive dates: `"last_30_days"`, `"this_month"`, `"yesterday"`, etc.
  - `resolve_date_range()` function for date calculations
  - `get_common_date_ranges()` to discover available options

* **NEW**: Enhanced parameter validation:
  - `get_available_metrics()` and `get_available_dimensions()` for discovery
  - Smart error messages with typo suggestions (e.g., "vews" → "views")
  - Comprehensive validation for filters, dimensions, and requirements

* **NEW**: Data transformation and export utilities:
  - `yt_to_dataframe()` - Convert API responses to clean data.frames
  - `yt_to_tibble()` - Modern tibble support  
  - `yt_export_csv()` - Easy CSV export with automatic naming
  - `yt_extract_summary()` - Statistical summaries
  - `yt_quick_plot()` - One-line visualizations

* **NEW**: Improved authentication and diagnostics:
  - Interactive OAuth setup guide for first-time users
  - `diagnose_tubern()` - Complete system health check
  - `check_api_quota()` - API usage monitoring
  - Better error messages and recovery suggestions

## Breaking Changes

* Removed test functions from package exports (internal use only)
* Enhanced `get_report()` with additional parameter validation

## Bug Fixes

* Fixed date parsing issues in quarter calculations
* Resolved duplicate documentation for internal functions  
* Fixed non-ASCII characters for CRAN compliance
* Improved error handling throughout the package

# tubern 0.3.0

## Major API Updates
* **BREAKING**: Updated to YouTube Analytics API v2 from deprecated v1
* **BREAKING**: Changed base URL from `youtube/analytics/v1` to `youtubeanalytics.googleapis.com/v2`
* **BREAKING**: Updated API parameter names to match v2 specification:
  - `start-date` → `startDate`
  - `end-date` → `endDate` 
  - `max-results` → `maxResults`
  - `start-index` → `startIndex`
  - `include-historical-channel-data` → `includeHistoricalChannelData`

## Authentication Improvements
* Added required `youtube.readonly` scope to OAuth authentication
* Updated OAuth scopes to match current API requirements
* Fixed authentication for both `analytics` and `monetary-analytics` scopes

## Function Updates
* `get_report()`: Fixed parameter mapping and improved documentation
* `list_groups()`: Enhanced parameter handling and examples
* `add_groups()`: Updated documentation with correct examples
* All functions: Updated API references to v2 documentation

## Documentation
* Comprehensive README rewrite with examples and setup instructions
* Added authentication setup guide
* Documented available metrics and dimensions
* Added API rate limiting information
* Updated all function references to point to v2 API documentation

## Bug Fixes
* Fixed test token file path issues
* Improved lintr test robustness
* Enhanced error handling for package detection

# version 0.2.1. 2025-03-25

* cross-ref issues + lazy data

# version 0.2.0 2016-11-08

* passes expect_lint_free
* add more args to get_report, plus defaults for args.

# version 0.1.0 2016-11-08

* initial release
