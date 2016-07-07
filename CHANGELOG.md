# Changelog

## v2.1.2 (2016-7-7)

* Bug fixes
  * Fix fastlane options being discarded


## v2.1.1 (2016-7-7)

* Bug fixes
  * Fix bad use of Keyword.merge

## v2.1.0 (2016-7-5)

* Enhancements
  * Support Phoenix 1.2
  * Replace `:eredis` with `Redix`

## v1.0.0 (2015-9-1)

* Enhancements
  * A redis `:url` can now be given as a configuration option

* Bug fixes
  * Establish optimistic connection on init to fix startup race conditions
  * Fix compounding reconnects if redis server is offline
