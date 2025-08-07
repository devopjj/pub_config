#!/bin/bash

# === CONFIG ===
VERSION="v1"
URL="https://mycdn.example.com/bashrc/bashrc_bundle-${VERSION}.tgz"
DEST="$HOME"
STAMP="$DEST/.bashrc.d/.installed_version"

echo "👉 Installing bashrc bundle version: $VERSION"

# Check existing version
if [[ -f "$STAMP" && "$(cat $STAMP)" == "$VERSION" ]]; then
  echo "✅ Already installed version $VERSION"
  exit 0
fi

# Download and extract
curl -fsSL "$URL" -o /tmp/bashrc_bundle.tgz || {
  echo "❌ Failed to download bundle"; exit 1;
}

tar xzf /tmp/bashrc_bundle.tgz -C "$DEST"
echo "$VERSION" > "$STAMP"

# Reload shell
echo "✅ Installed. Run 'exec bash' or open a new shell to apply changes."
