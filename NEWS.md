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
