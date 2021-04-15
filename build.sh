#!/usr/bin/env bash
set -euo pipefail

function usage() {
    echo "$0: <local|remote> [server-name]"
    echo "Builds, and runs (or installs) the image"
    echo "If remote, server-name is required, and the image will be pushed via cloudron."
    echo "If local, the image will be run locally."
    exit 1
}

if [ -z ${1+x} ]; then
    usage
fi
mode="$1"

if [[ "$mode" != "local" && "$mode" != "remote" ]]; then
    usage
fi

# Must be bumped every deploy it seems? Annoying...
# Hopefully we don't have any clock drift problems.
IMG_VERSION="0.0.$(date +%s)"
IMG_TAG="rburchell/inspircd:$IMG_VERSION"

echo "Building as $IMG_TAG"
podman build --format docker -t "$IMG_TAG" .

if [[ "$mode" == "local" ]]; then
    echo "Running locally"
    podman run --net=host "$IMG_TAG"
else
    # for remote use
    if [ -z ${2+x} ]; then
        echo "Server name to deploy to required."
        exit 1
    else
        SERVER_NAME="$2"
    fi

    podman push "$IMG_TAG"
    echo "Pushed image $IMG_TAG"

    echo "Deploying image to $SERVER_NAME"
    # install is first-time, then update every time afterwards.
    #cloudron install --image "docker.io/$IMG_TAG" --location "$SERVER_NAME"
    cloudron update --no-backup --app "$SERVER_NAME" --image "docker.io/$IMG_TAG"
    echo "Installed, hopefully"
fi

