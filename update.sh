#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix-prefetch-github go
# shellcheck shell=bash
set -euo pipefail

root="$(dirname "$(readlink -f "$0")")"
repo_root="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || echo "$root")"
cd "$repo_root"

versions_file="$root/versions.json"

# Use GITHUB_TOKEN when available for higher API rate limits
auth_header=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  auth_header="Authorization: Bearer ${GITHUB_TOKEN}"
fi

# Fetch latest version
latest_version=$(curl -fsSL -H "$auth_header" https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r '.tag_name | sub("^app/v"; "")')
echo "Updating hysteria to v${latest_version}..."

# Get src hash and rev via nix-prefetch-github
prefetch_data=$(nix run 'nixpkgs#nix-prefetch-github' -- --rev "app/v${latest_version}" apernet hysteria)
src_hash=$(echo "$prefetch_data" | jq -r '.hash')
rev=$(echo "$prefetch_data" | jq -r '.rev')

# Get date from GitHub API (YYYYMMDD format)
commit_data=$(curl -fsSL -H "$auth_header" "https://api.github.com/repos/apernet/hysteria/commits/${rev}")
date=$(echo "$commit_data" | jq -r '.commit.committer.date' | cut -c1-10 | tr -d '-')

# Extract libVersion from core/go.mod
libVersion=$(curl -fsSL "https://raw.githubusercontent.com/apernet/hysteria/app/v${latest_version}/core/go.mod" | awk '$1 == "github.com/apernet/quic-go" {print $2; exit}')

# Compute vendor hash
temp_dir=$(mktemp -d)
cleanup() { rm -rf "$temp_dir"; }
trap cleanup EXIT

curl -fsSL "https://github.com/apernet/hysteria/archive/refs/tags/app/v${latest_version}.tar.gz" \
  | tar xz -C "$temp_dir"
source_dir=$(find "$temp_dir" -maxdepth 1 -mindepth 1 -type d | head -1)

(cd "$source_dir/app" && GOWORK=off GOFLAGS=-mod=mod go mod vendor)
vendor_hash=$(nix hash path --sri "$source_dir/app/vendor")

# Write versions.json
jq -n \
  --arg version "$latest_version" \
  --arg hash "$src_hash" \
  --arg vendorHash "$vendor_hash" \
  --arg rev "$rev" \
  --arg date "$date" \
  --arg libVersion "$libVersion" \
  '{
    version: $version,
    hash: $hash,
    vendorHash: $vendorHash,
    rev: $rev,
    date: $date,
    libVersion: $libVersion
  }' > "$versions_file"

echo "hysteria updated to v${latest_version}"
echo "  rev:     ${rev}"
echo "  hash:    ${src_hash}"
echo "  vendor:  ${vendor_hash}"
echo "  quic-go: ${libVersion}"
