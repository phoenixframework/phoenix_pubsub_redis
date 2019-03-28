# Changelog

## master

## v2.1.7 (2018-3-28)

* Bug fixes
  * Fix incorrect error structure on :disconnected

## v2.1.6 (2018-3-4)

* Enhancements
  * Allow passing :ssl option to redix

## v2.1.5 (2018-1-2)

* Enhancements
  * Update redix and redix\_pubsub versions

## v2.1.4 (2017-10-9)

* Enhancements
  * Update redix and redix\_pubsub versions

## v2.1.3 (2017-2-21)

* Bug fixes
  * Handle disconnected Redis connections

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
