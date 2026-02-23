#!/usr/bin/env bash
#
# Publish @txnlab/* packages under the @d13co scope.
#
# Rewrites package names and cross-references in package.json files,
# runs pnpm publish for each package, then reverts all changes.
#
# Usage:
#   ./publish.sh [--dry-run] [--otp <code>] [--tag <tag>]
#
# Options:
#   --dry-run   Show what would be published without actually publishing
#   --otp       npm one-time password for 2FA
#   --tag       npm dist-tag (default: latest)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# ── Parse arguments ──────────────────────────────────────────────────
DRY_RUN=false
OTP=""
TAG="latest"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --otp)      OTP="$2"; shift 2 ;;
    --tag)      TAG="$2"; shift 2 ;;
    *)          echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Scope mapping ────────────────────────────────────────────────────
# Only @txnlab packages need renaming. @d13co packages keep their names.
FROM_SCOPE="@txnlab"
TO_SCOPE="@d13co"

# All package.json files that may contain @txnlab references (names or deps)
PACKAGE_JSONS=(
  "$ROOT/projects/use-wallet/packages/use-wallet/package.json"
  "$ROOT/projects/use-wallet/packages/use-wallet-react/package.json"
  "$ROOT/projects/use-wallet/packages/use-wallet-vue/package.json"
  "$ROOT/projects/use-wallet/packages/use-wallet-solid/package.json"
  "$ROOT/projects/use-wallet/packages/use-wallet-svelte/package.json"
  # use-wallet-ui-react has a peerDep on @txnlab/use-wallet-react
  "$ROOT/projects/use-wallet-ui/packages/react/package.json"
)

# Publishable packages in dependency order (core first, then adapters, then UI)
PUBLISH_DIRS=(
  "$ROOT/projects/use-wallet/packages/use-wallet"
  "$ROOT/projects/use-wallet/packages/use-wallet-react"
  "$ROOT/projects/use-wallet/packages/use-wallet-vue"
  "$ROOT/projects/use-wallet/packages/use-wallet-solid"
  "$ROOT/projects/use-wallet/packages/use-wallet-svelte"
  "$ROOT/projects/use-wallet-ui/packages/liquid-ui"
  "$ROOT/projects/use-wallet-ui/packages/react"
)

# ── Helpers ──────────────────────────────────────────────────────────
backup_suffix=".publish-backup"

# Bump the patch component of a semver string: 1.2.3 → 1.2.4
bump_patch() {
  local v="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$v"
  echo "${major}.${minor}.$((patch + 1))"
}

# Set the version in a package.json file
set_version() {
  local file="$1" new_version="$2"
  sed -i "s|\"version\": *\"[^\"]*\"|\"version\": \"${new_version}\"|" "$file"
}

backup_files() {
  for f in "${PACKAGE_JSONS[@]}"; do
    cp "$f" "${f}${backup_suffix}"
  done
}

restore_files() {
  for f in "${PACKAGE_JSONS[@]}"; do
    if [[ -f "${f}${backup_suffix}" ]]; then
      mv "${f}${backup_suffix}" "$f"
    fi
  done
}

rewrite_scope() {
  for f in "${PACKAGE_JSONS[@]}"; do
    # Replace @txnlab/ with @d13co/ in name fields and dependency references.
    # Uses sed to do a global find-replace. workspace:* references are preserved.
    sed -i "s|${FROM_SCOPE}/|${TO_SCOPE}/|g" "$f"
  done
}

# Always restore on exit
trap restore_files EXIT

# ── Main ─────────────────────────────────────────────────────────────
echo "==> Backing up package.json files"
backup_files

echo "==> Rewriting ${FROM_SCOPE} → ${TO_SCOPE}"
rewrite_scope

# Show what changed
echo ""
echo "==> Rewritten package names:"
for f in "${PACKAGE_JSONS[@]}"; do
  name=$(grep -m1 '"name"' "$f" | sed 's/.*"name": *"//;s/".*//')
  echo "    $name"
done
echo ""

# Build publish args
PUBLISH_ARGS=(--access public --tag "$TAG" --no-git-checks)
if [[ -n "$OTP" ]]; then
  PUBLISH_ARGS+=(--otp "$OTP")
fi

if $DRY_RUN; then
  echo "==> DRY RUN — would publish:"
  for dir in "${PUBLISH_DIRS[@]}"; do
    name=$(grep -m1 '"name"' "$dir/package.json" | sed 's/.*"name": *"//;s/".*//')
    version=$(grep -m1 '"version"' "$dir/package.json" | sed 's/.*"version": *"//;s/".*//')
    echo "    ${name}@${version}"
  done
  echo ""
  echo "    pnpm publish ${PUBLISH_ARGS[*]}"
else
  for dir in "${PUBLISH_DIRS[@]}"; do
    name=$(grep -m1 '"name"' "$dir/package.json" | sed 's/.*"name": *"//;s/".*//')
    version=$(grep -m1 '"version"' "$dir/package.json" | sed 's/.*"version": *"//;s/".*//')

    # Fetch latest published version from npm
    published=$(npm view "$name" version 2>/dev/null || echo "none")
    if [[ "$published" == "none" ]]; then
      echo ""
      echo "  ${name}  local: ${version}  npm: (not published)"
    else
      bumped=$(bump_patch "$published")
      echo ""
      echo "  ${name}  local: ${version}  npm: ${published}  bump: ${bumped}"
    fi

    echo -n "  [y] publish  [b] bump to ${bumped:-$version} & publish  [n] skip  [q] quit: "
    read -r answer
    case "$answer" in
      b|B)
        if [[ "$published" == "none" ]]; then
          echo "    Nothing to bump from, publishing as ${version}"
        else
          version="$bumped"
          set_version "$dir/package.json" "$version"
          echo "    Bumped to ${version}"
        fi
        echo "==> Publishing ${name}@${version}"
        (cd "$dir" && pnpm publish "${PUBLISH_ARGS[@]}")
        echo ""
        ;;
      y|Y)
        echo "==> Publishing ${name}@${version}"
        (cd "$dir" && pnpm publish "${PUBLISH_ARGS[@]}")
        echo ""
        ;;
      q|Q)
        echo "==> Aborting"
        exit 0
        ;;
      *)
        echo "    Skipped"
        ;;
    esac
  done
fi

echo "==> Restoring original package.json files"
# trap will handle restore
