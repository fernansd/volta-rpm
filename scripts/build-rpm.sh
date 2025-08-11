#!/usr/bin/env bash
set -euo pipefail

DISTRO=fedora
ARCH=$(uname -m)
MODE=source

while [[ $# -gt 0 ]]; do
  case $1 in
    --distro) DISTRO=$2; shift 2 ;;
    --arch) ARCH=$2; shift 2 ;;
    --mode) MODE=$2; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

IMAGE="volta-rpm-$DISTRO"
DIST_DIR="dist/$DISTRO/$ARCH"
mkdir -p "$DIST_DIR"

CONTAINER_CMD=${CONTAINER_CMD:-docker}
$CONTAINER_CMD build -f container/${DISTRO}.Dockerfile -t "$IMAGE" .

$CONTAINER_CMD run --rm -v "$PWD":/src -w /src "$IMAGE" bash -c "\
  rpmbuild --define '_topdir /src/build' \
           --define '_sourcedir /src/packaging/rpm/sources' \
           --define '_specdir /src/packaging/rpm' \
           --define 'dist .$(echo $DISTRO | tr -d -)' \
           --target $ARCH \
           -ba /src/packaging/rpm/volta.spec && \
  mv build/RPMS/*/*.rpm /src/$DIST_DIR/
"

echo "RPMs available under $DIST_DIR"
