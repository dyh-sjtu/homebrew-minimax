#!/bin/bash
# 更新 Casks/minimax-code.rb 的 version 与 sha256（国内 + 海外，arm64 + intel）。
# latest-mac.yml 只提供 sha512，cask 需要 sha256，所以会下载 4 个 DMG：
# 先用 yml 中的 sha512 校验完整性，再计算 sha256。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASK_FILE="$SCRIPT_DIR/../Casks/minimax-code.rb"

CN_BASE_URL="https://filecdn.minimax.chat/public/minimax-agent-prod/release"
GLOBAL_BASE_URL="https://file.cdn.minimax.io/public/minimax-agent-prod/release"
ARTIFACT_PREFIX="MiniMax Code"

VERSION=""
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $0 [--version VER] [--dry-run]

  --version VER   指定版本（默认读取 latest-mac.yml，并要求国内/海外版本一致）
  --dry-run       只打印结果，不修改 cask
EOF
}

log() { echo "[INFO] $*" >&2; }
die() { echo "[ERROR] $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help) usage; exit 0 ;;
        *) usage; die "Unknown option: $1" ;;
    esac
done

yml_version() { curl -fsS "$1/latest-mac.yml" | awk '/^version:/{print $2}'; }

if [ -z "$VERSION" ]; then
    cn_version=$(yml_version "$CN_BASE_URL")
    global_version=$(yml_version "$GLOBAL_BASE_URL")
    [ "$cn_version" = "$global_version" ] ||
        die "CN ($cn_version) and global ($global_version) versions differ, retry later or pass --version"
    VERSION=$cn_version
fi
[ -n "$VERSION" ] || die "Could not determine version"
log "Version: $VERSION"

WORK_DIR=$(mktemp -d)
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

# 输出 sha256 到 $WORK_DIR/<key>.sha256
fetch_and_hash() {
    local key=$1 base=$2 file=$3
    local url="$base/${file// /%20}"
    local tmp="$WORK_DIR/$key.dmg"

    log "Downloading $url"
    curl -fsSL -o "$tmp" "$url" || { echo "download failed: $url" > "$WORK_DIR/$key.err"; return; }

    local expected actual
    expected=$(curl -fsS "$base/latest-mac.yml" | grep -A1 "url: ${file}\$" | awk '/sha512:/{print $2}' || true)
    actual=$(openssl dgst -sha512 -binary "$tmp" | base64)
    if [ -z "$expected" ]; then
        log "WARN: $file not in latest-mac.yml, sha512 check skipped"
    elif [ "$expected" != "$actual" ]; then
        echo "sha512 mismatch: $url" > "$WORK_DIR/$key.err"
        return
    fi
    shasum -a 256 "$tmp" | awk '{print $1}' > "$WORK_DIR/$key.sha256"
    rm -f "$tmp"
}

fetch_and_hash cn_arm "$CN_BASE_URL" "$ARTIFACT_PREFIX-$VERSION-arm64.dmg" &
fetch_and_hash cn_intel "$CN_BASE_URL" "$ARTIFACT_PREFIX-$VERSION.dmg" &
fetch_and_hash global_arm "$GLOBAL_BASE_URL" "$ARTIFACT_PREFIX-$VERSION-arm64.dmg" &
fetch_and_hash global_intel "$GLOBAL_BASE_URL" "$ARTIFACT_PREFIX-$VERSION.dmg" &
wait

if ls "$WORK_DIR"/*.err >/dev/null 2>&1; then
    cat "$WORK_DIR"/*.err >&2
    die "Aborted, cask not modified"
fi

CN_ARM=$(cat "$WORK_DIR/cn_arm.sha256")
CN_INTEL=$(cat "$WORK_DIR/cn_intel.sha256")
GLOBAL_ARM=$(cat "$WORK_DIR/global_arm.sha256")
GLOBAL_INTEL=$(cat "$WORK_DIR/global_intel.sha256")

log "cn     arm64: $CN_ARM"
log "cn     intel: $CN_INTEL"
log "global arm64: $GLOBAL_ARM"
log "global intel: $GLOBAL_INTEL"

if [ "$DRY_RUN" = "true" ]; then
    log "[DRY-RUN] $CASK_FILE not modified"
    exit 0
fi

# cask 中 `if overseas` 分支在前（海外），`else` 分支在后（国内）
VERSION="$VERSION" CN_ARM="$CN_ARM" CN_INTEL="$CN_INTEL" \
GLOBAL_ARM="$GLOBAL_ARM" GLOBAL_INTEL="$GLOBAL_INTEL" \
perl -0pi -e '
    s/version "[^"]*"/version "$ENV{VERSION}"/;
    s/(if overseas\n\s+sha256 arm:\s+)"[0-9a-f]{64}"(,\n\s+intel:\s+)"[0-9a-f]{64}"/$1"$ENV{GLOBAL_ARM}"$2"$ENV{GLOBAL_INTEL}"/;
    s/(else\n\s+sha256 arm:\s+)"[0-9a-f]{64}"(,\n\s+intel:\s+)"[0-9a-f]{64}"/$1"$ENV{CN_ARM}"$2"$ENV{CN_INTEL}"/;
' "$CASK_FILE"

grep -q "$GLOBAL_ARM" "$CASK_FILE" && grep -q "$CN_ARM" "$CASK_FILE" ||
    die "Failed to write sha256 into $CASK_FILE"

log "Updated $CASK_FILE to $VERSION"
echo ""
echo "Next steps:"
echo "  git add Casks/minimax-code.rb"
echo "  git commit -m \"chore: bump minimax-code to $VERSION\""
echo "  git push"
