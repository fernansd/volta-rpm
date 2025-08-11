#!/usr/bin/env bash
set -euo pipefail

SPEC_FILE="packaging/rpm/volta.spec"
VERSION=${1:-}

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

sed -i -E "s/^Version: .*/Version: $VERSION/" "$SPEC_FILE"
# Update Source0 assuming tarball naming convention
sed -i -E "s|^(Source0: ).*|\1https://github.com/volta-cli/volta/releases/download/v$VERSION/volta-$VERSION-linux.tar.gz|" "$SPEC_FILE"

git add "$SPEC_FILE"
echo "Updated $SPEC_FILE to version $VERSION"
