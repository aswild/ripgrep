#!/bin/bash

run() {
    echo "+ $*" >&2
    "$@"
}

set -e

if [[ ! -f Cargo.lock ]]; then
    echo "Please run from the root of ripgrep's repo" >&2
    exit 1
fi

DOCKER_IMAGE=aswild/ripgrep-builder:bookworm
_uid=$(id -u)
_gid=$(id -g)

if ! docker inspect --type image $DOCKER_IMAGE &>/dev/null; then
    echo >&2 "Image $DOCKER_IMAGE not found, building"
    run docker build -t $DOCKER_IMAGE ci/docker/bookworm
fi

run docker run -ti --rm \
    --user "${_uid}:${_gid}" \
    --volume "$PWD:/ripgrep" \
    --workdir /ripgrep \
    $DOCKER_IMAGE \
    ci/build-deb --no-target
