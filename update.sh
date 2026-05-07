#!/usr/bin/env bash
# PS5 Control — update to the latest version from the jstnjx fork.
# Pulls source, rebuilds the daemon container, and prints any post-update
# steps, such as re-uploading the integration tarball if it changed.

set -euo pipefail

cd "$(dirname "$0")"

FORK_URL="https://github.com/jstnjx/ps5-control-uc.git"

CYAN="\033[1;36m"; GRN="\033[1;32m"; YEL="\033[1;33m"; RED="\033[1;31m"; OFF="\033[0m"
say()  { printf "${CYAN}==>${OFF} %s\n" "$1"; }
ok()   { printf "${GRN}✓${OFF}  %s\n" "$1"; }
warn() { printf "${YEL}!${OFF}  %s\n" "$1"; }
err()  { printf "${RED}✗${OFF}  %s\n" "$1" >&2; }

hash_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    shasum -a 256 "$file" | awk '{print $1}'
  fi
}

# --- 1. Sanity ----------------------------------------------------------------
if [[ ! -d .git ]]; then
  err "Not inside a git checkout. Updates require 'git clone'-ing the repo,"
  err "not extracting a downloaded zip."
  err "Workaround: re-clone the repo, run install.sh fresh, and copy/recreate"
  err "daemon/.pyremoteplay/ + daemon/.env from your old install."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  err "git required."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  err "Docker required."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  err "Docker Compose v2 required ('docker compose' command)."
  exit 1
fi

# --- 2. Ensure origin points to this fork -------------------------------------
CURRENT_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$CURRENT_ORIGIN" ]]; then
  warn "No git remote named origin found — adding jstnjx fork as origin."
  git remote add origin "$FORK_URL"
elif [[ "$CURRENT_ORIGIN" != "$FORK_URL" && "$CURRENT_ORIGIN" != "git@github.com:jstnjx/ps5-control-uc.git" ]]; then
  warn "origin currently points to: $CURRENT_ORIGIN"
  warn "Switching origin to: $FORK_URL"
  git remote set-url origin "$FORK_URL"
else
  ok "origin points to jstnjx fork."
fi

# --- 3. Track current version -------------------------------------------------
PREV_REV="$(git rev-parse HEAD 2>/dev/null || echo "unknown")"

PREV_TARBALL_HASH=""
if [[ -f integration/ps5-uc-integration.tar.gz ]]; then
  PREV_TARBALL_HASH="$(hash_file integration/ps5-uc-integration.tar.gz)"
fi

# --- 4. Stash local edits, preserving profile/env -----------------------------
if ! git diff --quiet || ! git diff --cached --quiet; then
  warn "You have local changes — stashing before pull."
  warn "You can restore them afterward with: git stash pop"
  git stash push -m "pre-update auto-stash $(date -u +%Y-%m-%dT%H:%M:%SZ)" || true
fi

# --- 5. Pull ------------------------------------------------------------------
say "Pulling latest from GitHub fork..."
git fetch origin

DEFAULT_BRANCH="$(git remote show origin | sed -n 's/.*HEAD branch: //p')"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

git pull --ff-only origin "$DEFAULT_BRANCH"

NEW_REV="$(git rev-parse HEAD)"
if [[ "$PREV_REV" == "$NEW_REV" ]]; then
  ok "Already up to date ($NEW_REV)."
else
  ok "Updated $PREV_REV -> $NEW_REV"
fi

# --- 6. Verify local runtime files --------------------------------------------
if [[ ! -f daemon/.env ]]; then
  warn "daemon/.env not found. Run ./install.sh if PS5_HOST is not configured."
else
  ok "daemon/.env present."
fi

if [[ ! -f daemon/.pyremoteplay/.profile.json ]]; then
  warn "daemon/.pyremoteplay/.profile.json not found."
  warn "You may need to run ./install.sh again to pair Remote Play."
else
  ok "pyremoteplay profile present."
fi

# --- 7. Rebuild + restart daemon ---------------------------------------------
cd daemon

say "Rebuilding daemon container..."
docker compose build

say "Restarting daemon..."
docker compose up -d --force-recreate

ok "Daemon running."
cd ..

# --- 8. Did the integration tarball change? -----------------------------------
NEW_TARBALL_HASH=""
if [[ -f integration/ps5-uc-integration.tar.gz ]]; then
  NEW_TARBALL_HASH="$(hash_file integration/ps5-uc-integration.tar.gz)"
fi

echo
echo "============================================================"
ok "Update complete."

if [[ -n "$NEW_TARBALL_HASH" && "$PREV_TARBALL_HASH" != "$NEW_TARBALL_HASH" ]]; then
  warn "The Remote 3 integration tarball changed in this update."
  echo "    -> Re-upload integration/ps5-uc-integration.tar.gz to your Remote 3:"
  echo "       Settings -> Integrations -> Custom -> Upload"
else
  ok "Remote 3 integration unchanged — no upload needed."
fi

echo
echo "Useful commands:"
echo "  cd daemon && docker compose logs -f"
echo "  cd daemon && docker compose down"
echo "  ./install.sh"
echo "============================================================"