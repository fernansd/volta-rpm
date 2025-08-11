#!/usr/bin/env bash
set -euo pipefail

RPM=${1:-}
if [[ -z "$RPM" ]]; then
  echo "Usage: $0 <rpm-file>" >&2
  exit 1
fi

DISTRO=${DISTRO:-fedora}
IMAGE="volta-rpm-$DISTRO-test"
CONTAINER_CMD=${CONTAINER_CMD:-docker}

$CONTAINER_CMD build -f container/${DISTRO}.Dockerfile -t "$IMAGE" .
$CONTAINER_CMD run --rm -v "$PWD":/src -w /src "$IMAGE" bash -c "\
  dnf -y install /src/$RPM && \
  volta --version && \
  volta help >/dev/null
"
