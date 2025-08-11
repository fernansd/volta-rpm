#!/usr/bin/env bash
set -euo pipefail

REPO="volta-cli/volta"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
HTML_URL="https://github.com/$REPO/releases/latest"

# Try GitHub API first
TAG=$(curl -fsSL "$API_URL" | jq -r '.tag_name' 2>/dev/null || true)

if [[ -z "$TAG" || "$TAG" == "null" ]]; then
  # Fallback to scraping HTML
  TAG=$(curl -fsSL "$HTML_URL" | grep -o 'releases/tag/[^" ]*' | head -n1 | awk -F/ '{print $3}')
fi

if [[ -z "$TAG" ]]; then
  echo "Failed to determine latest Volta release" >&2
  exit 1
fi

echo "$TAG"
