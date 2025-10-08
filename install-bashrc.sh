#!/bin/bash
#================================================
# filename: install-bashrc.sh
# filedesc: Auto upgrade bashrc bundle with force reinstall
# modified: 2025-10-08 23:42:49
# version: 2.3
#================================================

set -euo pipefail
IFS=$'\n\t'
umask 077

# === CONFIG ===
DEST="${HOME}/env.j"
STAMP="${DEST}/.bashrc.d/.installed_version"
BASE_URL="https://github.com/devopjj/pub_config/releases/download/"
API_BASE="https://api.github.com/repos/devopjj/pub_config"
R2_PUBLIC_DOMAIN="https://r2.cas88.top"
# 默认值初始化
FORCE_INSTALL=false
INSTALL_BIN=true
USE_MIRROR="auto"

# 二进制工具配置
BIN_URL="${R2_PUBLIC_DOMAIN}/env.j_bin.tgz"
BIN_INSTALL_DIR="/usr/local/bin"

# ✅ R2 镜像配置
R2_MIRROR_ENABLED="${R2_MIRROR_ENABLED:-true}"
R2_MIRROR_URL="${R2_MIRROR_URL:-${R2_PUBLIC_DOMAIN}/bashrc}"  # 替换为你的域名

# curl base opts
CURL_OPTS=(--fail --silent --show-error --location --retry 3 --retry-delay 1 --max-time 60)

# === PARSE ARGUMENTS ===
while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -f|--force) 
        FORCE_INSTALL=true
        shift 
        ;;
    --skip-bin)
        INSTALL_BIN=false
        shift
        ;;
    --use-github) 
        R2_MIRROR_ENABLED=false
        shift 
        ;;
    --use-r2) 
        R2_MIRROR_ENABLED=true
        shift 
        ;;
    --r2-url) 
        R2_MIRROR_URL="$2"
        shift 2 
        ;;
    -h|--help)
      cat <<'USAGE'
Usage: install-bashrc.sh [OPTIONS]
  -f, --force       Force reinstall even if same version
  --skip-bin        Skip installing binary tools to /usr/local/bin
  --use-github      Force use GitHub (skip mirror)
  --use-r2          Force use R2 mirror
  --r2-url <url>    Custom R2 mirror URL
  -h, --help        Show this help
USAGE
      exit 0 
      ;;
    *) 
        echo "❌ Unknown option: $1"
        exit 1 
        ;;
  esac
done

# === GitHub API helper ===
gh_api() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl "${CURL_OPTS[@]}" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$@"
  else
    curl "${CURL_OPTS[@]}" -H "Accept: application/vnd.github+json" "$@"
  fi
}

# 智能选择下载源
select_download_source() {
    if [[ "$USE_MIRROR" == "github" ]]; then
        echo "github"
        return
    fi
    
    if [[ "$USE_MIRROR" == "r2" ]]; then
        echo "r2"
        return
    fi
    
    # 自动检测（简化版：直接尝试 R2）
    if [[ "$R2_MIRROR_ENABLED" == "true" ]]; then
        # 测试 R2 可访问性
        if curl -sf --connect-timeout 3 "${R2_MIRROR_URL}/bashrc_bundle-latest.tgz" -o /dev/null 2>/dev/null; then
            echo "r2"
            return
        fi
    fi
    
    echo "github"
}

# === GitHub API helper (supports GITHUB_TOKEN if provided) ===
gh_api() {
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl "${CURL_OPTS[@]}" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$@"
  else
    curl "${CURL_OPTS[@]}" -H "Accept: application/vnd.github+json" "$@"
  fi
}

# === Get latest version (prefer releases, fallback to tags) ===
get_latest_version() {
  local ver=""
  ver=$(gh_api "${API_BASE}/releases/latest" 2>/dev/null | grep -m1 '"tag_name":' | cut -d'"' -f4 || true)
  if [[ -z "${ver}" || "${ver}" == "null" ]]; then
    ver=$(gh_api "${API_BASE}/tags?per_page=1" 2>/dev/null | grep -m1 '"name":' | cut -d'"' -f4 || true)
  fi
  if [[ -z "${ver}" ]]; then
    echo "v2"
  else
    echo "${ver}"
  fi
}

LATEST_VERSION="$(get_latest_version)"
CURRENT_VERSION=""

echo "👉 Latest version: ${LATEST_VERSION}"

# === Check current version ===
if [[ -f "${STAMP}" ]]; then
  CURRENT_VERSION="$(cat "${STAMP}" || true)"
  echo "📋 Current version: ${CURRENT_VERSION}"
  if [[ "${CURRENT_VERSION}" == "${LATEST_VERSION}" && "${FORCE_INSTALL}" != true ]]; then
    echo "✅ Already up to date (${CURRENT_VERSION})"
    echo "💡 Use -f or --force to reinstall"
    exit 0
  fi
fi

if [[ "${FORCE_INSTALL}" == true ]]; then
  echo "🔄 Force reinstalling ${LATEST_VERSION}"
elif [[ -z "${CURRENT_VERSION}" ]]; then
  echo "📦 First time installation of ${LATEST_VERSION}"
else
  echo "🚀 Upgrading from ${CURRENT_VERSION} to ${LATEST_VERSION}"
fi

# === Download artifacts ===
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/bashrc.XXXXXX")"
trap 'rm -rf "${TMPDIR}"' EXIT

BUNDLE_TGZ="${TMPDIR}/bashrc_bundle.tgz"
BUNDLE_LIST="${TMPDIR}/bashrc_bundle.list"

DOWNLOAD_SOURCE=$(select_download_source)

# 构建下载 URL
if [[ "$DOWNLOAD_SOURCE" == "r2" ]]; then
    BUNDLE_URL="${R2_MIRROR_URL}/bashrc_bundle-${LATEST_VERSION}.tgz"
    LIST_URL="${R2_MIRROR_URL}/bashrc_bundle-${LATEST_VERSION}.list"
    echo "🇨🇳 Using R2 mirror"
else
    BUNDLE_URL="${BASE_URL}/${LATEST_VERSION}/bashrc_bundle-${LATEST_VERSION}.tgz"
    LIST_URL="${BASE_URL}/${LATEST_VERSION}/bashrc_bundle-${LATEST_VERSION}.list"
    echo "🌍 Using GitHub"
fi
echo "📥 Downloading bundle: ${BUNDLE_URL}"
curl "${CURL_OPTS[@]}" -o "${BUNDLE_TGZ}" "${BUNDLE_URL}" || { echo "❌ Failed to download bundle"; exit 1; }

echo "📥 Downloading list:   ${LIST_URL}"
if ! curl "${CURL_OPTS[@]}" -o "${BUNDLE_LIST}" "${LIST_URL}"; then
  echo "⚠️  Missing .list file; will proceed without pre-check list"
  : > "${BUNDLE_LIST}"
fi

# === Install (idempotent) ===
mkdir -p "${DEST}/.bashrc.d"

if [[ "${FORCE_INSTALL}" == true && -d "${DEST}" ]]; then
  echo "🧹 Cleaning existing installation dir: ${DEST}"
  rm -rf "${DEST}"
  mkdir -p "${DEST}/.bashrc.d"
fi

echo "📦 Extracting to ${DEST}"
tar xzf "${BUNDLE_TGZ}" -C "${DEST}"

# === Record version ===
echo "${LATEST_VERSION}" > "${STAMP}"

# === Symlink dotfiles (only for entries from bundle list, fallback to tar listing) ===
echo "🔗 Linking dotfiles to \$HOME"

# Build file list from .list or from tar content
declare -a LINK_ITEMS=()
if [[ -s "${BUNDLE_LIST}" ]]; then
  mapfile -t LINK_ITEMS < <(grep -E '^\.' "${BUNDLE_LIST}" || true)
else
  mapfile -t LINK_ITEMS < <(tar tzf "${BUNDLE_TGZ}" | grep -E '^\.' || true)
fi

for rel in "${LINK_ITEMS[@]}"; do
  # only top-level dotfiles/dirs we just extracted
  [[ "${rel}" =~ ^\.[A-Za-z0-9._-]+(/.*)?$ ]] || continue
  src="${DEST}/${rel}"
  tgt="${HOME}/${rel##*/}"

  if [[ ! -e "${src}" && ! -L "${src}" ]]; then
    echo "Skip missing in DEST: ${rel}"
    continue
  fi

  # Backup once if target exists and is not symlink
  if [[ -e "${tgt}" && ! -L "${tgt}" ]]; then
    if [[ ! -e "${tgt}.bak" && ! -e "${tgt}.pre-envj.bak" ]]; then
      cp -a "${tgt}" "${tgt}.pre-envj.bak" || true
      echo "🗄  Backup ${tgt} -> ${tgt}.pre-envj.bak"
    fi
    rm -rf "${tgt}"
  fi

  ln -snf "${src}" "${tgt}"
  echo "link: ${tgt} -> ${src}"
done

# === Optional: ops-toolkit (private repo) ===
echo "🔧 ops-toolkit (optional)"
if [[ -n "${OPS_PAT_READONLY:-}" ]]; then
  pushd "${HOME}" >/dev/null
  rm -rf ops-toolkit || true
  # use ephemeral creds; avoid storing PAT
  git -c credential.helper= clone "https://devopjj:${OPS_PAT_READONLY}@github.com/devopjj/ops-toolkit.git" || {
    echo "⚠️  Failed to clone ops-toolkit, continuing..."
  }
  popd >/dev/null
else
  echo "⚠️  OPS_PAT_READONLY not set, skipping private ops-toolkit"
fi

# === Done ===
if [[ "${FORCE_INSTALL}" == true ]]; then
  echo "✅ Force reinstalled ${LATEST_VERSION}. Run 'exec bash' to apply."
elif [[ -z "${CURRENT_VERSION}" ]]; then
  echo "✅ Installed ${LATEST_VERSION}. Run 'exec bash' to apply."
else
  echo "✅ Upgraded to ${LATEST_VERSION}. Run 'exec bash' to apply."
fi
