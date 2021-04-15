# FIXME

* Verify downloaded debian package hash at build time
* Better healthchecker: actually try to ensure that the ircd is up/responding periodically?
* LDAP not really working... why?
* Vet & rethink default modules some more...
* Improve logging: https://github.com/inspircd/inspircd/issues/1860
* Consider using conf templating variables rather than doing it using shell script?
* In start.sh, if an existing config exists in /app/data/, copy from it, rather than the templated one.
  (do a copy, so that we can do the variable replacements...)
* In our templated config, include "/app/data/customize.conf", so small tweaks to configuration can be made?
* Remove 'cat' of config on startup, since that's a bit annoying
