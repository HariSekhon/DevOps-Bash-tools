Tests
=====

Unlike the `tests/` directory of my other repos, most of the scripts in this repo are actually really used and tested via the CI of most of my other repos that use it as a submodule, while some other scripts aren't easily testable as their require non-trivial infrastructure (eg. Cloudera) or local access keys.

`spotify_uri_to_name.sh` has its alternate modes tested here only because adjacent scripts and repos only use its original design for track conversions.
