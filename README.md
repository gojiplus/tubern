## tubern: R Client for the YouTube Analytics and Reporting API

[![CRAN_Status_Badge](https://www.r-pkg.org:443/badges/version/tubern)](https://www.r-pkg.org:443/badges/version/tubern)
![](https://cranlogs.r-pkg.org/badges/grand-total/tubern)
[![R-CMD-check](https://github.com/gojiplus/tubern/actions/workflows/R-CMD-check.yml/badge.svg)](https://github.com/gojiplus/tubern/actions/workflows/R-CMD-check.yml)

tubern provides an R interface to the [YouTube Analytics API v2](https://developers.google.com/youtube/analytics), allowing you to retrieve YouTube Analytics data for channels and content owners. The package supports authentication via OAuth 2.0 and provides functions for getting analytics reports and managing channel groups.

## Features

- **🚀 Enhanced User Experience**: Simplified functions for common analytics tasks
- **📅 Smart Date Handling**: Use intuitive relative dates like "last_30_days", "this_month"
- **🔍 Intelligent Validation**: Get helpful suggestions for metrics, dimensions, and parameters
- **📊 Built-in Data Transformation**: Convert API responses to data.frames, tibbles, and CSV exports
- **📈 Quick Visualization**: Generate plots with one function call
- **🛠️ Advanced Error Handling**: Informative error messages and diagnostic tools
- **🔐 Streamlined Authentication**: Step-by-step OAuth setup with automatic scope detection
- **⚡ Pre-built Report Templates**: Channel overview, top videos, demographics, and more
- **🌍 Geographic & Demographic Analysis**: Built-in support for audience insights
- **💰 Revenue Analytics**: Comprehensive monetization reporting (with proper OAuth scope)

## Installation

### From CRAN
```r
install.packages("tubern")
```

### Development version from GitHub
```r
# install.packages("devtools")
devtools::install_github("gojiplus/tubern", build_vignettes = TRUE)
```

## Quick Start

### 1. Easy Authentication Setup

```r
library(tubern)

# First time? Get step-by-step setup guide
yt_oauth()

# With your credentials (basic analytics)
yt_oauth("your-client-id.apps.googleusercontent.com", "your-client-secret")

# For revenue data (requires special permission)
yt_oauth("your-client-id.apps.googleusercontent.com", "your-client-secret", scope = "monetary")
```

### 2. Get Analytics with Smart Dates

```r
# Use intuitive relative dates - no more manual date calculations!
overview <- get_channel_overview("last_30_days")
daily_trends <- get_daily_performance("this_month") 
top_videos <- get_top_videos("last_7_days")

# Or use traditional dates
report <- get_report(
  ids = "channel==MINE",
  metrics = "views,likes,comments",
  start_date = "2024-01-01",
  end_date = "2024-01-31"
)
```

### 3. Instant Data Analysis & Visualization

```r
# Convert to data.frame with clean column names
df <- yt_to_dataframe(daily_trends)
head(df)

# Quick visualization
yt_quick_plot(daily_trends)    # Auto-detects best chart type
yt_quick_plot(top_videos, chart_type = "bar")

# Export to CSV
yt_export_csv(overview, "my_channel_overview.csv")

# Get summary statistics
summary <- yt_extract_summary(overview)
```

### 4. Pre-built Analytics Templates

```r
# Channel performance overview
overview <- get_channel_overview("last_30_days")

# Top performing videos
top_videos <- get_top_videos("last_7_days", max_results = 20)

# Audience demographics
demographics <- get_audience_demographics("last_90_days")

# Geographic performance
geo_performance <- get_geographic_performance("this_month")

# Device/platform breakdown
device_performance <- get_report(
  ids = "channel==MINE",
  metrics = "views,estimatedMinutesWatched", 
  dimensions = "deviceType",
  start_date = "last_30_days"
)

# Revenue analysis (requires monetary scope)
revenue <- get_revenue_report("last_month")
```

### 5. Smart Validation & Help

```r
# Get available metrics and dimensions
get_available_metrics()
get_available_dimensions()

# Helpful error messages with suggestions
# get_report(ids = "channel==MINE", metrics = "vews", start_date = "last_7_days")
# → Error: Invalid metric(s): vews. Did you mean: 'vews' -> 'views'?

# Diagnostic tools
diagnose_tubern()  # Check setup
check_api_quota()  # Monitor API usage
```

## API Reference

### Core Functions

- `yt_oauth()`: Set up OAuth 2.0 authentication
- `get_report()`: Retrieve YouTube Analytics reports
- `list_groups()`: List channel groups
- `add_groups()`: Create new channel groups
- `update_group()`: Modify existing groups
- `delete_group()`: Remove groups
- `list_group_items()`: List items in a group
- `add_group_item()`: Add channels to groups
- `delete_group_item()`: Remove channels from groups

### Available Metrics

Common metrics you can request include:
- `views`: Number of times videos were viewed
- `likes`, `dislikes`: Engagement metrics
- `shares`: Number of times videos were shared
- `comments`: Number of comments
- `subscribersGained`, `subscribersLost`: Subscriber changes
- `estimatedMinutesWatched`: Total watch time in minutes
- `averageViewDuration`: Average time spent watching

For monetary metrics (requires monetary-analytics scope):
- `estimatedRevenue`: Estimated revenue
- `estimatedAdRevenue`: Revenue from ads (renamed from `adEarnings`)
- `cpm`: Cost per thousand impressions (renamed from `impressionBasedCpm`)

### Available Dimensions

Dimensions allow you to segment your data:
- `video`: Individual video performance
- `day`: Daily breakdowns
- `country`: Geographic data
- `deviceType`: Desktop, mobile, tablet, etc.
- `operatingSystem`: OS breakdowns
- `ageGroup`, `gender`: Demographic data (limited availability)

## Authentication Setup

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the YouTube Analytics API
4. Create OAuth 2.0 credentials (Desktop application type)
5. Use the client ID and secret in `yt_oauth()`

For detailed authentication instructions, see the [YouTube Analytics API documentation](https://developers.google.com/youtube/analytics/registering_an_application).

## Important Notes

- **API Changes**: This package has been updated to use YouTube Analytics API v2. Some parameter names and behaviors may have changed from previous versions.
- **Rate Limits**: The YouTube Analytics API has usage quotas. See the [quota usage documentation](https://developers.google.com/youtube/analytics/quota) for details.
- **Data Freshness**: Analytics data typically has a delay of 24-72 hours.

## Related Resources

- [YouTube Analytics API Documentation](https://developers.google.com/youtube/analytics)
- [YouTube Data API R Client](https://github.com/gojiplus/tuber) (for video metadata, not analytics)
- [Google APIs R Client](https://github.com/r-lib/gargle) (for general Google API authentication)

## License

Released under the [MIT License](http://opensource.org/licenses/MIT).

## Contributing

Contributions are welcome! Please read the [Contributor Code of Conduct](https://www.contributor-covenant.org/version/1/0/0/) and submit issues or pull requests on GitHub.

## Support

For bug reports and feature requests, please use the [GitHub issue tracker](https://github.com/gojiplus/tubern/issues).
