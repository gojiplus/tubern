This is a patch release for version 0.5.1, fixing defects in request
construction, parameter validation, and error handling.

## Test environments

* local macOS (Tahoe 26.3.1), R 4.5.2
* GitHub Actions: ubuntu (devel, release, oldrel-1), macOS, windows
* win-builder (devel, release)

## R CMD check results
There were no ERRORs, WARNINGs or NOTEs.

## Summary of changes

* A relative `end_date` resolved to the start of its own window rather than the
  end, silently shortening every report that used one. Routing it through the
  end-of-range mapper fixed that, but an unrecognised range then fell through to
  a default of "today", so a typo silently widened the report instead. Both
  paths now report an unrecognised range rather than guessing at one.

* Two revenue metrics used names the API had since renamed, so requests
  carrying them did not return the intended columns.

* The retry helper forced the same promise on each attempt, which memoised the
  first result so a retry replayed a stale value, and it signalled "retry" with
  `NULL`, which a genuine `NULL` result was indistinguishable from.

* Only HTTP 200 counted as success, so a 204 from the documented delete
  endpoints was treated as a failure; and the error path indexed a body that is
  `raw(0)` when empty, which errors on an atomic vector.

* The local registry of valid dimensions and metrics had drifted from the API
  reference in both directions. Several documented dimensions were rejected
  before a request was ever made; two metrics that exist only in the bulk
  Reporting API were accepted and produced a request the targeted-query endpoint
  rejects; and two content owner filters were listed as requestable dimensions.

* The vignette used literal example values in its `yt_oauth()` call. They are
  now placeholders.

## Reverse dependencies
There are no reverse dependencies.
