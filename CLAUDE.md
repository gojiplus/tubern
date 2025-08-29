# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About tubern

tubern is an R package that provides a client for the YouTube Analytics and Reporting API. The package allows users to authenticate with YouTube, retrieve analytics reports, and manage group resources.

## Common Development Commands

### Testing
- Run all tests: `testthat::test_dir("tests")`
- Run specific test file: `testthat::test_file("tests/testthat/test-get-report.R")`
- Test with coverage: `covr::package_coverage()`

### Code Quality
- Lint package: `lintr::lint_package()`
- Check package: `R CMD check --no-manual --as-cran .`
- Build documentation: `roxygen2::roxygenise()`

### Installation and Building
- Install from source: `devtools::install()`
- Build package: `R CMD build .`
- Install with vignettes: `devtools::install(build_vignettes = TRUE)`

## Architecture

### Core Components

**Authentication (`R/yt_oauth.R`)**
- `yt_oauth()`: Main authentication function that handles OAuth2 flow
- `yt_check_token()`: Validates that authentication token exists
- Uses `.httr-oauth` file for token persistence

**HTTP Client (`R/tubern.R`)**
- Base API URL: `https://www.googleapis.com/youtube/analytics/v1`
- Core HTTP wrapper functions: `tubern_GET()`, `tubern_POST()`, `tubern_PUT()`, `tubern_DELETE()`
- Internal `.api_request()` handles all API communication with authentication

**API Functions (R/ directory)**
- `get_report()`: Main analytics reporting function
- Group management: `list_groups()`, `add_groups()`, `update_group()`, `delete_group()`
- Group item management: `list_group_items()`, `add_group_item()`, `delete_group_item()`

### Key Dependencies
- `httr`: HTTP client for API requests and OAuth2 authentication
- `jsonlite`: JSON parsing for API responses
- `testthat`: Testing framework
- `httptest`: HTTP request mocking for tests
- `lintr`: Code style checking

### Testing Structure
- Uses `httptest` for mocking HTTP requests in tests
- Fixture files stored in `tests/testthat/__httptest__/`
- Token file `tests/testthat/token_file.rds.enc` for encrypted test credentials
- Comprehensive test coverage across all API functions

### API Patterns
All API functions follow consistent patterns:
- Take query parameters as function arguments
- Build query list and pass to appropriate HTTP method
- Return raw API response as named list
- Include comprehensive parameter documentation with YouTube API references