# Changelog

## Development

## v3.1.0 (2026-03-26)

### Enhancements

* Delegate Redis connection options to Redix, replacing hand-rolled URL parsing

### Deprecations

* Top-level Redis connection keys (:host, :port, :password, :url, etc.) are deprecated in favor of the :redis\_opts option

## v3.0.1 (2021-06-14)
  * Bump redix dependency

## v3.0.0 (2020-04-14)

  * Depend on Phoenix.PubSub v2.0
