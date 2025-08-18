#!/bin/bash
#================================================
# filename: install-bashrc.sh
# filedesc: Auto upgrade bashrc bundle
# modified: 2025-08-18, 12:03
#================================================

# === CONFIG ===
VERSION="v1"
DEST="$HOME"
URL="https://github.com/devopjj/pub_config/raw/refs/heads/master/bashrc_bundle-${VERSION}.tgz"
BASE_URL="https://github.com/devopjj/pub_config/raw/refs/heads/master"
STAMP="$DEST/.bashrc.d/.installed_version"

echo "👉 Installing bashrc bundle version: $VERSION"

# Check existing version
#if [[ -f "$STAMP" && "$(cat $STAMP)" == "$VERSION" ]]; then
#  echo "✅ Already installed version $VERSION"
#  exit 0
#fi

# Download and extract
curl -fsSL "$URL" -o /tmp/bashrc_bundle.tgz || {
  echo "❌ Failed to download bundle"; exit 1;
}

tar xzf /tmp/bashrc_bundle.tgz -C "$DEST"
echo "$VERSION" > "$STAMP"

# ops-toolkis
cd $HOME
PAT_READONLY="XXX"
owner="devopjj"
repo="ops-toolkit"
git clone https://devopjj:$PAT_READONLY@github.com/${owner}/${repo}.git

# Reload shell
echo "✅ Installed. Run 'exec bash' or open a new shell to apply changes."
