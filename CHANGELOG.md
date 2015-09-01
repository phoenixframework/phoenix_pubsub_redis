# Changelog

## v1.0.0 (2015-9-1)

* Enhancements
  * A redis `:url` can now be given as a configuration option

* Bug fixes
  * Establish optimistic connection on init to fix startup race conditions
  * Fix compounding reconnects if redis server is offline
