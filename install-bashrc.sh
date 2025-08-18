#!/bin/bash
#================================================
# filename: install-bashrc.sh
# filedesc: Auto upgrade bashrc bundle
# modified: 2025-08-18, 12:03
#================================================

# === CONFIG ===
VERSION="v1"
DEST="$HOME"
STAMP="$DEST/.bashrc.d/.installed_version"
URL="https://github.com/devopjj/pub_config/raw/refs/heads/master/bashrc_bundle-${VERSION}.tgz"
BASE_URL="https://github.com/devopjj/pub_config/raw/refs/heads/master"

# Get latest version from GitHub releases or tags
get_latest_version() {
  curl -fsSL "https://api.github.com/repos/devopjj/pub_config/releases/latest" 2>/dev/null | \
  grep '"tag_name":' | cut -d'"' -f4 || echo "v2"
}

LATEST_VERSION=$(get_latest_version)
CURRENT_VERSION=""

# Check current version
if [[ -f "$STAMP" ]]; then
  CURRENT_VERSION=$(cat "$STAMP")
  echo "📋 Current version: $CURRENT_VERSION"
  
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✅ Already up to date ($CURRENT_VERSION)"
    exit 0
  fi
fi

echo "🚀 Upgrading from $CURRENT_VERSION to $LATEST_VERSION"

# Download and extract
URL="${BASE_URL}/bashrc_bundle-${LATEST_VERSION}.tgz"
curl -fsSL "$URL" -o /tmp/bashrc_bundle.tgz || {
  echo "❌ Failed to download $URL"; exit 1;
}

mkdir -p "$DEST/.bashrc.d"
tar xzf /tmp/bashrc_bundle.tgz -C "$DEST"
echo "$LATEST_VERSION" > "$STAMP"
rm -f /tmp/bashrc_bundle.tgz


# ops-toolkis
cd $HOME
PAT_READONLY="XXX"
owner="devopjj"
repo="ops-toolkit"
git clone https://devopjj:$PAT_READONLY@github.com/${owner}/${repo}.git

# Reload shell
echo "✅ Installed. Run 'exec bash' or open a new shell to apply changes."
