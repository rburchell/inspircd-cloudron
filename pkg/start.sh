#!/bin/bash
set -eu

# Ensure this exists...
touch /app/data/permchannels.conf
touch /app/data/xline.db

# ensure that data directory is owned by 'cloudron' user
chown -R cloudron:cloudron /app/data

rm -rf /run/inspircd/
mkdir /run/inspircd/

DH_PATH="/run/inspircd/dhparams.pem"
if [ ! -f "$DH_PATH" ]; then
    echo "==> Generating dhparams"
    certtool --generate-dh-params --sec-param normal --outfile "$DH_PATH"
else
    echo "==> dhparams OK"
fi

# Allow for local running, without Cloudron, for test purposes
if [ -z ${CLOUDRON_APP_DOMAIN+x} ]; then
    echo "==> Not running on Cloudron; generating self-signed certificate, and picking a default server name..."
    CLOUDRON_APP_DOMAIN="test.example.org"

    CERTTOOL_TEMPLATE_FILE="/run/inspircd/certtool.tmpl"
    echo "cn = \"$CLOUDRON_APP_DOMAIN\"" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "organization = \"IRC\"" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "serial = 1" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "expiration_days = 365" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "ca" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "signing_key" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "cert_signing_key" >> "$CERTTOOL_TEMPLATE_FILE"
    echo "crl_signing_key" >> "$CERTTOOL_TEMPLATE_FILE"

    # We assume there's no certificate available, and generate a sad, self-signed one...
    certtool --generate-privkey --outfile /run/inspircd/tls_key.pem
    certtool --generate-self-signed --load-privkey /run/inspircd/tls_key.pem --outfile /run/inspircd/tls_cert.pem --template="$CERTTOOL_TEMPLATE_FILE"
    rm "$CERTTOOL_TEMPLATE_FILE"
    unset CERTTOOL_TEMPLATE_FILE
    
    TEMPLATE_SSL_CERTIFICATE_PATH="/run/inspircd"
    TEMPLATE_LDAP_SERVER="ldap://localhost"
    TEMPLATE_LDAP_BIND_DN="cn=Manager,dc=inspircd,dc=org"
    TEMPLATE_LDAP_BIND_AUTH="mysecretpass"
    TEMPLATE_LDAP_USERS_BASE_DN="ou=People,dc=brainbox,dc=cc"
else
    echo "==> Running on Cloudron as $CLOUDRON_APP_DOMAIN"
    TEMPLATE_SSL_CERTIFICATE_PATH="/etc/certs"
    TEMPLATE_LDAP_SERVER="${CLOUDRON_LDAP_URL}"
    TEMPLATE_LDAP_BIND_DN="${CLOUDRON_LDAP_BIND_DN}"
    TEMPLATE_LDAP_BIND_AUTH="${CLOUDRON_LDAP_BIND_PASSWORD}"
    TEMPLATE_LDAP_USERS_BASE_DN="${CLOUDRON_LDAP_USERS_BASE_DN}"

    # Allow our writing to /dev/stdout as a log device...
    # This is imperfect, but awaits a better solution.
    # See:
    # - https://github.com/inspircd/inspircd/issues/1860
    # - https://github.com/moby/moby/issues/31243
    # For whatever reason, this doesn't seem to be a problem when running under podman,
    # so I'll leave it in the Cloudron-only branch.
    chmod o+w /dev/stdout
fi

# NB: BELOW THIS POINT, no modifying /run/inspircd please.
chown -R cloudron:cloudron /run/inspircd/

TEMPLATE_SERVER_NAME="$CLOUDRON_APP_DOMAIN"
TEMPLATE_SERVER_DESCRIPTION="Cloudron at $CLOUDRON_APP_DOMAIN"
TEMPLATE_SERVER_NETWORK="$CLOUDRON_APP_DOMAIN"

TEMPLATE_ADMIN_NAME="Cloudron Admin"
TEMPLATE_ADMIN_NICK="CloudronAdmin"
TEMPLATE_ADMIN_EMAIL="cloudron.admin@$CLOUDRON_APP_DOMAIN"

# Allow user overrides of our config templating...
if [ -f "/app/data/env" ]; then
    echo "==> Loading user-provided environment overrides"
    source /app/data/env
else
    echo "==> No user-provided environment found"
fi

CONFIG_FILE_PATH="/run/inspircd/inspircd.conf"
echo "==> Preparing configuration for $CLOUDRON_APP_DOMAIN in $CONFIG_FILE_PATH"
cp /app/pkg/inspircd.conf.template "$CONFIG_FILE_PATH"

# Could also use <define> blocks rather than doing this ourselves... Not sure if it's worth it or not.
echo "\t- Server configuration..."
sed -i'' "s/TEMPLATE_SERVER_NAME/${TEMPLATE_SERVER_NAME//\//\\/}/g" "$CONFIG_FILE_PATH"
sed -i'' "s/TEMPLATE_SERVER_DESCRIPTION/${TEMPLATE_SERVER_DESCRIPTION//\//\\/}/g" "$CONFIG_FILE_PATH"
sed -i'' "s/TEMPLATE_SERVER_NETWORK/${TEMPLATE_SERVER_NETWORK//\//\\/}/g" "$CONFIG_FILE_PATH"

echo "\t- Admin configuration..."
sed -i'' "s/TEMPLATE_ADMIN_NAME/${TEMPLATE_ADMIN_NAME//\//\\/}/g" "$CONFIG_FILE_PATH"
sed -i'' "s/TEMPLATE_ADMIN_NICK/${TEMPLATE_ADMIN_NICK//\//\\/}/g" "$CONFIG_FILE_PATH"
sed -i'' "s/TEMPLATE_ADMIN_EMAIL/${TEMPLATE_ADMIN_EMAIL//\//\\/}/g" "$CONFIG_FILE_PATH"

echo "\t- SSL configuration..."
sed -i'' "s/TEMPLATE_SSL_CERTIFICATE_PATH/${TEMPLATE_SSL_CERTIFICATE_PATH//\//\\/}/g" $CONFIG_FILE_PATH

echo "\t- LDAP configuration..."
sed -i'' "s/TEMPLATE_LDAP_SERVER/${TEMPLATE_LDAP_SERVER//\//\\/}/g" $CONFIG_FILE_PATH
sed -i'' "s/TEMPLATE_LDAP_BIND_DN/${TEMPLATE_LDAP_BIND_DN//\//\\/}/g" $CONFIG_FILE_PATH
sed -i'' "s/TEMPLATE_LDAP_BIND_AUTH/${TEMPLATE_LDAP_BIND_AUTH//\//\\/}/g" $CONFIG_FILE_PATH
sed -i'' "s/TEMPLATE_LDAP_USERS_BASE_DN/${TEMPLATE_LDAP_USERS_BASE_DN//\//\\/}/g" $CONFIG_FILE_PATH

echo "Configuration after templating:"
cat $CONFIG_FILE_PATH

echo "==> Starting inspircd"
exec /usr/local/bin/gosu cloudron:cloudron inspircd --nofork --config "$CONFIG_FILE_PATH"
