#!/usr/bin/env bash
set -euxo pipefail

################################################################################
#
# Setting Default Variable Values
# Tokaido enables us to set variable values at three levels. These levels
# are as follows, listed from highest-priority to lowest-priority
# 1 - As Config Variable in .tok/config.yml
# 2 - As Environment Variable exposed to the PHP container
# 3 - As default variable defined here
# 
# For example, if the variable FASTCGI_BUFFERS is defined in .tok/config.yml
# then any value set as an environment variable (FASTCGI_BUFFERS) won't be used
#
################################################################################

# Default Values
DEFAULT_WORKER_CONNECTIONS="1024"
DEFAULT_TYPES_HASH_MAX_SIZE="2048"
DEFAULT_CLIENT_MAX_BODY_SIZE="1024m"
DEFAULT_KEEPALIVE_TIMEOUT="65"
DEFAULT_FASTCGI_READ_TIMEOUT="300"
DEFAULT_FASTCGI_BUFFERS="16 16k"
DEFAULT_FASTCGI_BUFFER_SIZE="32k"
DEFAULT_DRUPAL_ROOT="docroot"

# Config values, if set. Otherwise, yq will set to 'null'
TOK_WORKER_CONNECTIONS="$(yq r /tokaido/site/.tok/config.yml nginx.workerconnections)"
TOK_TYPES_HASH_MAX_SIZE="$(yq r /tokaido/site/.tok/config.yml nginx.hashmaxsize)"
TOK_CLIENT_MAX_BODY_SIZE="$(yq r /tokaido/site/.tok/config.yml nginx.clientmaxbodysize)"
TOK_KEEPALIVE_TIMEOUT="$(yq r /tokaido/site/.tok/config.yml nginx.keepalivetimeout)"
TOK_FASTCGI_READ_TIMEOUT="$(yq r /tokaido/site/.tok/config.yml nginx.fastcgireadtimeout)"
TOK_FASTCGI_BUFFERS="$(yq r /tokaido/site/.tok/config.yml nginx.fastcgibuffers)"
TOK_FASTCGI_BUFFER_SIZE="$(yq r /tokaido/site/.tok/config.yml nginx.fastcgibuffersize)"
TOK_DRUPAL_ROOT="$(yq r /tokaido/site/.tok/config.yml drupal.path)"

# Iterate over the variable configurations to get the highest-precedence value
if [ "${TOK_WORKER_CONNECTIONS}" != "null" ]; then
    # Tokaido config values have highest precedence, so we'll just use that
    WORKER_CONNECTIONS="${TOK_WORKER_CONNECTIONS}"
else
    # Use an env var value, or our default if none is set
    WORKER_CONNECTIONS="${WORKER_CONNECTIONS:-$DEFAULT_WORKER_CONNECTIONS}"
fi

if [ "${TOK_TYPES_HASH_MAX_SIZE}" != "null" ]; then
    TYPES_HASH_MAX_SIZE="${TOK_TYPES_HASH_MAX_SIZE}"
else
    TYPES_HASH_MAX_SIZE="${TYPES_HASH_MAX_SIZE:-$DEFAULT_TYPES_HASH_MAX_SIZE}"
fi

if [ "${TOK_CLIENT_MAX_BODY_SIZE}" != "null" ]; then
    CLIENT_MAX_BODY_SIZE="${TOK_CLIENT_MAX_BODY_SIZE}"
else
    CLIENT_MAX_BODY_SIZE="${CLIENT_MAX_BODY_SIZE:-$DEFAULT_CLIENT_MAX_BODY_SIZE}"
fi

if [ "${TOK_KEEPALIVE_TIMEOUT}" != "null" ]; then
    KEEPALIVE_TIMEOUT="${TOK_KEEPALIVE_TIMEOUT}"
else
    KEEPALIVE_TIMEOUT="${KEEPALIVE_TIMEOUT:-$DEFAULT_KEEPALIVE_TIMEOUT}"
fi

if [ "${TOK_FASTCGI_READ_TIMEOUT}" != "null" ]; then
    FASTCGI_READ_TIMEOUT="${TOK_FASTCGI_READ_TIMEOUT}"
else
    FASTCGI_READ_TIMEOUT="${FASTCGI_READ_TIMEOUT:-$DEFAULT_FASTCGI_READ_TIMEOUT}"
fi

if [ "${TOK_FASTCGI_BUFFERS}" != "null" ]; then
    FASTCGI_BUFFERS="${TOK_FASTCGI_BUFFERS}"
else
    FASTCGI_BUFFERS="${FASTCGI_BUFFERS:-$DEFAULT_FASTCGI_BUFFERS}"
fi

if [ "${TOK_FASTCGI_BUFFER_SIZE}" != "null" ]; then
    FASTCGI_BUFFER_SIZE="${TOK_FASTCGI_BUFFER_SIZE}"
else
    FASTCGI_BUFFER_SIZE="${FASTCGI_BUFFER_SIZE:-$DEFAULT_FASTCGI_BUFFER_SIZE}"
fi

if [ "${TOK_DRUPAL_ROOT}" != "null" ]; then
    DRUPAL_ROOT="${TOK_DRUPAL_ROOT}"
else
    DRUPAL_ROOT="${DRUPAL_ROOT:-$DEFAULT_DRUPAL_ROOT}"
fi

# Strip any forward-slashes out of our resolve drupal root, just in case
DRUPAL_ROOT=$(echo $DRUPAL_ROOT | sed -e 's/\///g')

# FPM_HOSTNAME is a special value that can only be provided 
# as environment variables, not via the .tok/config.yml file. 

FPM_HOSTNAME=${FPM_HOSTNAME:-fpm}

################################################################################
#
# Setting Config Files Paths
# Tokaido can use Nginx config files to completely override the config
# files included in this Docker image. For example, if the file 
# .tok/nginx/redirects.conf exists, it will be used for all redirect config
# instead of the default. 
#
# These config files can be used in conjunction with the above config values
# as well, so you can both use your own config file and per-environment
# overrides from environment variables, for example. 
# 
################################################################################

DEFAULT_NGINX_CONFIG="/tokaido/config/nginx/nginx.conf"
DEFAULT_HOST_CONFIG="/tokaido/config/nginx/host.conf"
DEFAULT_MIMETYPES_CONFIG="/tokaido/config/nginx/mimetypes.conf"
DEFAULT_REDIRECTS_CONFIG="/tokaido/config/nginx/redirects.conf"
DEFAULT_ADDITIONAL_CONFIG="/tokaido/config/nginx/additional.conf"

CUSTOM_NGINX_CONFIG="/tokaido/site/.tok/nginx/nginx.conf"
CUSTOM_HOST_CONFIG="/tokaido/site/.tok/nginx/host.conf"
CUSTOM_MIMETYPES_CONFIG="/tokaido/site/.tok/nginx/mimetypes.conf"
CUSTOM_REDIRECTS_CONFIG="/tokaido/site/.tok/nginx/redirects.conf"
CUSTOM_ADDITIONAL_CONFIG="/tokaido/site/.tok/nginx/additional.conf"

if [ -f "${CUSTOM_NGINX_CONFIG}" ]; then
    NGINX_CONFIG="${CUSTOM_NGINX_CONFIG}"
else 
    NGINX_CONFIG="${DEFAULT_NGINX_CONFIG}"
fi

if [ -f "${CUSTOM_HOST_CONFIG}" ]; then
    HOST_CONFIG="${CUSTOM_HOST_CONFIG}"
else 
    HOST_CONFIG="${DEFAULT_HOST_CONFIG}"
fi

if [ -f "${CUSTOM_MIMETYPES_CONFIG}" ]; then
    MIMETYPES_CONFIG="${CUSTOM_MIMETYPES_CONFIG}"
else 
    MIMETYPES_CONFIG="${DEFAULT_MIMETYPES_CONFIG}"
fi

if [ -f "${CUSTOM_REDIRECTS_CONFIG}" ]; then
    REDIRECTS_CONFIG="${CUSTOM_REDIRECTS_CONFIG}"
else 
    REDIRECTS_CONFIG="${DEFAULT_REDIRECTS_CONFIG}"
fi

if [ -f "${CUSTOM_ADDITIONAL_CONFIG}" ]; then
    ADDITIONAL_CONFIG="${CUSTOM_ADDITIONAL_CONFIG}"
else 
    ADDITIONAL_CONFIG="${DEFAULT_ADDITIONAL_CONFIG}"
fi

if [ -f "${CUSTOM_ADDITIONAL_CONFIG}" ]; then
    ADDITIONAL_CONFIG="${CUSTOM_ADDITIONAL_CONFIG}"
else 
    ADDITIONAL_CONFIG="${DEFAULT_ADDITIONAL_CONFIG}"
fi


# Output all our resolved values for logging to catch

echo "config value 'WORKER_CONNECTIONS'   :: ${WORKER_CONNECTIONS}"
echo "config value 'TYPES_HASH_MAX_SIZE'  :: ${TYPES_HASH_MAX_SIZE}"
echo "config value 'CLIENT_MAX_BODY_SIZE' :: ${CLIENT_MAX_BODY_SIZE}"
echo "config value 'KEEPALIVE_TIMEOUT'    :: ${KEEPALIVE_TIMEOUT}"
echo "config value 'FASTCGI_READ_TIMEOUT' :: ${FASTCGI_READ_TIMEOUT}"
echo "config value 'FASTCGI_BUFFERS'      :: ${FASTCGI_BUFFERS}"
echo "config value 'FASTCGI_BUFFER_SIZE'  :: ${FASTCGI_BUFFER_SIZE}"
echo "config value 'DRUPAL_ROOT'          :: ${DRUPAL_ROOT}"
echo "config value 'FPM_HOSTNAME'         :: ${FPM_HOSTNAME}"
echo "config file 'nginx.conf'            :: ${NGINX_CONFIG}"
echo "config file 'host.conf'             :: ${HOST_CONFIG}"
echo "config file 'mimetypes.conf'        :: ${MIMETYPES_CONFIG}"
echo "config file 'redirects.conf'        :: ${REDIRECTS_CONFIG}"
echo "config file 'additional.conf'       :: ${ADDITIONAL_CONFIG}"

# Finally, place all our defined variables into their respective config files
sed -i "s/{{.WORKER_CONNECTIONS}}/${WORKER_CONNECTIONS}/g" "${NGINX_CONFIG}"
sed -i "s/{{.TYPES_HASH_MAX_SIZE}}/${TYPES_HASH_MAX_SIZE}/g" "${NGINX_CONFIG}"
sed -i "s/{{.CLIENT_MAX_BODY_SIZE}}/${CLIENT_MAX_BODY_SIZE}/g" "${NGINX_CONFIG}"
sed -i "s/{{.KEEPALIVE_TIMEOUT}}/${KEEPALIVE_TIMEOUT}/g" "${NGINX_CONFIG}"
sed -i "s/{{.FASTCGI_READ_TIMEOUT}}/${FASTCGI_READ_TIMEOUT}/g" "${HOST_CONFIG}"
sed -i "s/{{.FASTCGI_BUFFERS}}/${FASTCGI_BUFFERS}/g" "${HOST_CONFIG}"
sed -i "s/{{.FASTCGI_BUFFER_SIZE}}/${FASTCGI_BUFFER_SIZE}/g" "${HOST_CONFIG}"
sed -i "s/{{.DRUPAL_ROOT}}/${DRUPAL_ROOT}/g" "${HOST_CONFIG}"
sed -i "s/{{.FPM_HOSTNAME}}/${FPM_HOSTNAME}/g" "${HOST_CONFIG}"

sed -i "s/{{.HOST_CONFIG}}/${HOST_CONFIG//\//\\\/}/g" "${NGINX_CONFIG}"
sed -i "s/{{.MIMETYPES_CONFIG}}/${MIMETYPES_CONFIG//\//\\\/}/g" "${NGINX_CONFIG}"
sed -i "s/{{.REDIRECTS_CONFIG}}/${REDIRECTS_CONFIG//\//\\\/}/g" "${HOST_CONFIG}"
sed -i "s/{{.ADDITIONAL_CONFIG}}/${ADDITIONAL_CONFIG//\//\\\/}/g" "${HOST_CONFIG}"

nginx -c "${NGINX_CONFIG}"
