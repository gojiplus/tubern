# tubern 0.4.0

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
