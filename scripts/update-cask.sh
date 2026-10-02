#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASKS_DIR="$SCRIPT_DIR/../Casks"

# URLs
GLOBAL_YML_URL="https://file.cdn.minimax.io/public/minimax-agent-prod/release/latest-mac.yml"
CN_YML_URL="https://filecdn.minimax.chat/public/minimax-agent-prod/release/latest-mac.yml"

GLOBAL_BASE_URL="https://file.cdn.minimax.io/public/minimax-agent-prod/release"
CN_BASE_URL="https://filecdn.minimax.chat/public/minimax-agent-prod/release"

# 3.1.0 起中英文包 productName 统一为 "MiniMax Code"
ARTIFACT_PREFIX="MiniMax%20Code"

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --global        Update minimax-agent (global version) only"
    echo "  --cn            Update minimax (China version) only"
    echo "  --all           Update both versions (default)"
    echo "  --version VER   Specify version (otherwise fetches from latest-mac.yml)"
    echo "  --dry-run       Show what would be done without making changes"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Update both to latest version"
    echo "  $0 --global             # Update global version only"
    echo "  $0 --cn --version 3.1.0 # Update CN version to 3.1.0"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get version from latest-mac.yml
get_latest_version() {
    local yml_url=$1
    curl -fs "$yml_url" | grep "^version:" | awk '{print $2}'
}

# Download file, verify sha512 against latest-mac.yml, then calculate sha256
# (latest-mac.yml 只提供 sha512，Homebrew cask 需要 sha256)
calculate_sha256() {
    local url=$1
    local yml_url="${url%/*}/latest-mac.yml"
    local file_name=$(basename "$url" | sed 's/%20/ /g')
    local tmp_file=$(mktemp)
    
    log_info "Downloading: $url" >&2
    if curl -fL -s -o "$tmp_file" "$url"; then
        local expected=$(curl -fs "$yml_url" | grep -A1 "url: ${file_name}\$" | awk '/sha512:/{print $2}')
        local actual=$(openssl dgst -sha512 -binary "$tmp_file" | base64)
        if [ -n "$expected" ] && [ "$expected" != "$actual" ]; then
            rm -f "$tmp_file"
            log_error "sha512 mismatch for $file_name" >&2
            return 1
        fi
        [ -z "$expected" ] && log_warn "$file_name not found in latest-mac.yml, skip sha512 check" >&2
        local sha=$(shasum -a 256 "$tmp_file" | awk '{print $1}')
        rm -f "$tmp_file"
        echo "$sha"
    else
        rm -f "$tmp_file"
        log_error "Failed to download: $url" >&2
        return 1
    fi
}

# Update cask file
update_cask() {
    local cask_file=$1
    local version=$2
    local sha_arm64=$3
    local sha_intel=$4
    local dry_run=$5
    
    if [ "$dry_run" = "true" ]; then
        log_info "[DRY-RUN] Would update $cask_file:"
        log_info "  version: $version"
        log_info "  sha256 (arm64): $sha_arm64"
        log_info "  sha256 (intel): $sha_intel"
        return 0
    fi
    
    # Update version
    sed -i '' "s/version \"[^\"]*\"/version \"$version\"/" "$cask_file"
    
    # Update sha256 (format: sha256 arm: "...", intel: "...")
    sed -i '' -E "s/(sha256 arm: +)\"[^\"]*\"/\1\"$sha_arm64\"/" "$cask_file"
    sed -i '' -E "s/(intel: +)\"[^\"]*\"/\1\"$sha_intel\"/" "$cask_file"
    
    log_info "Updated $cask_file to version $version"
}

# Update global version (minimax-agent)
update_global() {
    local version=$1
    local dry_run=$2
    
    log_info "Updating minimax-agent (global version)..."
    
    if [ -z "$version" ]; then
        version=$(get_latest_version "$GLOBAL_YML_URL")
        log_info "Latest version: $version"
    fi
    
    if [ -z "$version" ]; then
        log_error "Could not determine version"
        return 1
    fi
    
    local arm64_url="${GLOBAL_BASE_URL}/${ARTIFACT_PREFIX}-${version}-arm64.dmg"
    local intel_url="${GLOBAL_BASE_URL}/${ARTIFACT_PREFIX}-${version}.dmg"
    
    local sha_arm64=$(calculate_sha256 "$arm64_url")
    local sha_intel=$(calculate_sha256 "$intel_url")
    
    if [ -z "$sha_arm64" ] || [ -z "$sha_intel" ]; then
        log_error "Failed to calculate sha256"
        return 1
    fi
    
    update_cask "$CASKS_DIR/minimax-agent.rb" "$version" "$sha_arm64" "$sha_intel" "$dry_run"
}

# Update CN version (minimax)
update_cn() {
    local version=$1
    local dry_run=$2
    
    log_info "Updating minimax (China version)..."
    
    if [ -z "$version" ]; then
        version=$(get_latest_version "$CN_YML_URL")
        log_info "Latest version: $version"
    fi
    
    if [ -z "$version" ]; then
        log_error "Could not determine version"
        return 1
    fi
    
    local arm64_url="${CN_BASE_URL}/${ARTIFACT_PREFIX}-${version}-arm64.dmg"
    local intel_url="${CN_BASE_URL}/${ARTIFACT_PREFIX}-${version}.dmg"
    
    local sha_arm64=$(calculate_sha256 "$arm64_url")
    local sha_intel=$(calculate_sha256 "$intel_url")
    
    if [ -z "$sha_arm64" ] || [ -z "$sha_intel" ]; then
        log_error "Failed to calculate sha256"
        return 1
    fi
    
    update_cask "$CASKS_DIR/minimax.rb" "$version" "$sha_arm64" "$sha_intel" "$dry_run"
}

# Main
UPDATE_GLOBAL=false
UPDATE_CN=false
VERSION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            UPDATE_GLOBAL=true
            shift
            ;;
        --cn)
            UPDATE_CN=true
            shift
            ;;
        --all)
            UPDATE_GLOBAL=true
            UPDATE_CN=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Default: update both
if [ "$UPDATE_GLOBAL" = "false" ] && [ "$UPDATE_CN" = "false" ]; then
    UPDATE_GLOBAL=true
    UPDATE_CN=true
fi

if [ "$UPDATE_GLOBAL" = "true" ]; then
    update_global "$VERSION" "$DRY_RUN"
fi

if [ "$UPDATE_CN" = "true" ]; then
    update_cn "$VERSION" "$DRY_RUN"
fi

log_info "Done!"

if [ "$DRY_RUN" = "false" ]; then
    echo ""
    log_info "Next steps:"
    echo "  cd $(dirname "$CASKS_DIR")"
    echo "  git add Casks/"
    echo "  git commit -m \"chore: bump version to ${VERSION:-latest}\""
    echo "  git push"
fi
