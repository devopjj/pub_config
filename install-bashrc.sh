#!/bin/bash
#================================================
# filename: install-bashrc.sh
# filedesc: Auto upgrade bashrc bundle with force reinstall
# modified: 2025-08-18, 12:03
#================================================

# === CONFIG ===
DEST="$HOME/env.j"
STAMP="$DEST/.bashrc.d/.installed_version"
BASE_URL="https://github.com/devopjj/pub_config/raw/refs/heads/master"
FORCE_INSTALL=false

# === PARSE ARGUMENTS ===
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      FORCE_INSTALL=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -f, --force    Force reinstall even if same version"
      echo "  -h, --help     Show this help"
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Use -h for help"
      exit 1
      ;;
  esac
done

# Get latest version from GitHub releases or tags
get_latest_version() {
  curl -fsSL "https://api.github.com/repos/devopjj/pub_config/releases/latest" 2>/dev/null | \
  grep '"tag_name":' | cut -d'"' -f4 || echo "v2"
}

LATEST_VERSION=$(get_latest_version)
CURRENT_VERSION=""

echo "👉 Latest version: $LATEST_VERSION"

# Check current version
if [[ -f "$STAMP" ]]; then
  CURRENT_VERSION=$(cat "$STAMP")
  echo "📋 Current version: $CURRENT_VERSION"
  
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" && "$FORCE_INSTALL" != true ]]; then
    echo "✅ Already up to date ($CURRENT_VERSION)"
    echo "💡 Use -f or --force to reinstall"
    exit 0
  fi
fi

if [[ "$FORCE_INSTALL" == true ]]; then
  echo "🔄 Force reinstalling $LATEST_VERSION"
  # 清理现有安装
  if [[ -d "$DEST" ]]; then
    echo "🧹 Cleaning existing installation..."
    rm -rf "$DEST/.bashrc" "$DEST/.bash_profile" "$DEST/.bashrc.d" 2>/dev/null
  fi
elif [[ -z "$CURRENT_VERSION" ]]; then
  echo "📦 First time installation of $LATEST_VERSION"
else
  echo "🚀 Upgrading from $CURRENT_VERSION to $LATEST_VERSION"
fi

# Download and extract
URL="${BASE_URL}/bashrc_bundle-${LATEST_VERSION}.tgz"
echo "📥 Downloading from: $URL"

curl -fsSL "$URL" -o /tmp/bashrc_bundle.tgz || {
  echo "❌ Failed to download $URL"; exit 1;
}

mkdir -p "$DEST/.bashrc.d"
tar xzf /tmp/bashrc_bundle.tgz -C "$DEST"
echo "$LATEST_VERSION" > "$STAMP"
rm -f /tmp/bashrc_bundle.tgz

# ops-toolkit (private repo, needs PAT)
cd $HOME
PAT_READONLY="${OPS_PAT_READONLY:-}"
if [[ -n "$PAT_READONLY" ]]; then
  echo "🔧 Installing ops-toolkit..."
  [[ -d "ops-toolkit" ]] && rm -rf ops-toolkit
  git clone "https://devopjj:${PAT_READONLY}@github.com/devopjj/ops-toolkit.git" || {
    echo "⚠️  Failed to clone ops-toolkit, continuing..."
  }
else
  echo "⚠️  OPS_PAT_READONLY not set, skipping private ops-toolkit"
fi

if [[ "$FORCE_INSTALL" == true ]]; then
  echo "✅ Force reinstalled $LATEST_VERSION. Run 'exec bash' to apply changes."
elif [[ -z "$CURRENT_VERSION" ]]; then
  echo "✅ Installed $LATEST_VERSION. Run 'exec bash' to apply changes."
else
  echo "✅ Upgraded to $LATEST_VERSION. Run 'exec bash' to apply changes."
fi