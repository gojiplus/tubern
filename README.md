## tubern: R Client for the YouTube Analytics and Reporting API

[![CRAN_Status_Badge](https://www.r-pkg.org:443/badges/version/tubern)](https://www.r-pkg.org:443/badges/version/tubern)
![](https://cranlogs.r-pkg.org/badges/grand-total/tubern)
[![R-CMD-check](https://github.com/gojiplus/tubern/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gojiplus/tubern/actions)

tubern provides an R interface to the [YouTube Analytics API v2](https://developers.google.com/youtube/analytics), allowing you to retrieve YouTube Analytics data for channels and content owners. The package supports authentication via OAuth 2.0 and provides functions for getting analytics reports and managing channel groups.

## Features

- **Analytics Reports**: Retrieve detailed analytics data including views, likes, dislikes, watch time, and more
- **OAuth 2.0 Authentication**: Secure authentication with YouTube Analytics API
- **Group Management**: Create, list, update, and delete channel groups
- **Flexible Querying**: Support for dimensions, filters, sorting, and date ranges
- **Content Owner Support**: Access analytics for channels you manage as a content owner

## Installation

### From CRAN
```r
install.packages("tubern")
```

### Development version from GitHub
```r
# install.packages("devtools")
devtools::install_github("soodoku/tubern", build_vignettes = TRUE)
```

## Quick Start

### 1. Authentication

First, you need to set up OAuth 2.0 authentication. You'll need to create a Google Cloud project and obtain OAuth 2.0 credentials:

```r
library(tubern)

# Set up authentication (you'll need your own client ID and secret)
yt_oauth(app_id = "your_client_id.apps.googleusercontent.com",
         app_secret = "your_client_secret")
```

### 2. Get Analytics Reports

```r
# Get basic view statistics for your channel
report <- get_report(
  ids = "channel==MINE",
  metrics = "views,likes,dislikes,shares",
  start_date = "2024-01-01",
  end_date = "2024-12-31"
)

# Get data with dimensions
report_by_video <- get_report(
  ids = "channel==MINE",
  metrics = "views,averageViewDuration",
  dimensions = "video",
  start_date = "2024-01-01",
  end_date = "2024-12-31",
  max_results = 25
)
```

### 3. Manage Channel Groups

```r
# List your channel groups
groups <- list_groups(filter = c(mine = TRUE))

# Create a new group
new_group <- add_groups(
  snippet = list(
    title = "My Channel Group",
    description = "A group for organizing my channels"
  )
)
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
- `adEarnings`: Revenue from ads
- `impressionBasedCpm`: Cost per thousand impressions

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

For bug reports and feature requests, please use the [GitHub issue tracker](https://github.com/soodoku/tubern/issues).
