# FIXME

* Include sha256 for Dockerfile FROM
* Update version in manfest to match packaged version
* Healthcheck won't work, since it requires a 200 code.
  Remove m_httpd, and somehow set up a dummy web instance that checks TCP state?
  And maybe request some feature improvements @ Cloudron to help this.
* LDAP not really working... why?
* Vet & rethink default modules some more...
* Ask upstream for a 'console' log method? inspircd.log sucks.
* Consider using conf templating variables rather than doing it using shell script?
* In start.sh, if an existing config exists in /app/data/, copy from it, rather than the templated one.
  (do a copy, so that we can do the variable replacements...)
* In our templated config, include "/app/data/customize.conf", so small tweaks to configuration can be made?
* Remove 'cat' of config on startup, since that's a bit annoying
