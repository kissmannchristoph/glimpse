#!/bin/sh

# Cargo Zigbuild - Build for All Platforms
# POSIX-compatible version (works with /bin/sh)
# Builds your Rust binary for macOS, Linux, and Windows

cd "$(dirname "$0")" || exit
cd ".."

rm -rf ./dist


set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BLUE}   🔧 Cargo Zigbuild - Universal Builder${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get binary name from Cargo.toml
BINARY_NAME=$(grep '^name' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "${YELLOW}📦 Building ${BINARY_NAME} v${VERSION}${NC}"
echo ""

# Check if cargo-zigbuild is installed
if ! command -v cargo-zigbuild >/dev/null 2>&1; then
    echo "${RED}❌ cargo-zigbuild not found${NC}"
    echo "${YELLOW}Install it with: cargo install cargo-zigbuild${NC}"
    exit 1
fi

# Check if zig is installed
if ! command -v zig >/dev/null 2>&1; then
    echo "${RED}❌ zig not found${NC}"
    echo "${YELLOW}Install it with:${NC}"
    echo "  macOS:  brew install zig"
    echo "  Linux:  snap install zig --classic --beta"
    echo "  Or:     https://ziglang.org/download/"
    exit 1
fi

echo "${GREEN}✅ Prerequisites installed${NC}"
echo ""

# Define targets as a simple list
TARGETS=""

# Help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --all              Build all targets (default)"
    echo "  --macos            Build macOS only (Intel + ARM)"
    echo "  --linux            Build Linux only (x64 + ARM)"
    echo "  --windows          Build Windows only (x64 + x86)"
    echo "  --quick            Build essential targets only"
    echo "  --list             List all available targets"
    echo ""
    echo "Examples:"
    echo "  $0                 # Build all targets"
    echo "  $0 --macos         # Build macOS only"
    echo "  $0 --quick         # Build x64 only (fast)"
    exit 0
fi

# List targets
if [ "$1" = "--list" ]; then
    echo "Available targets:"
    echo "  macOS:"
    echo "    - x86_64-apple-darwin (Intel)"
    echo "    - aarch64-apple-darwin (M1/M2/M3/M4)"
    echo "  Linux:"
    echo "    - x86_64-unknown-linux-gnu"
    echo "    - x86_64-unknown-linux-musl (static)"
    echo "    - aarch64-unknown-linux-gnu"
    echo "    - aarch64-unknown-linux-musl (static)"
    echo "  Windows:"
    echo "    - x86_64-pc-windows-gnu (64-bit)"
    echo "    - i686-pc-windows-gnu (32-bit)"
    exit 0
fi

# Determine which targets to build
if [ "$1" = "--macos" ]; then
    TARGETS="x86_64-apple-darwin aarch64-apple-darwin"
elif [ "$1" = "--linux" ]; then
    TARGETS="x86_64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-gnu aarch64-unknown-linux-musl"
elif [ "$1" = "--windows" ]; then
    TARGETS="x86_64-pc-windows-gnu i686-pc-windows-gnu"
elif [ "$1" = "--quick" ]; then
    TARGETS="aarch64-apple-darwin x86_64-unknown-linux-musl x86_64-pc-windows-gnu"
else
    # Default: all targets
    TARGETS="x86_64-apple-darwin aarch64-apple-darwin x86_64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-gnu aarch64-unknown-linux-musl x86_64-pc-windows-gnu i686-pc-windows-gnu"
fi

# Count targets
TARGET_COUNT=$(echo "$TARGETS" | wc -w)

echo "${BLUE}━━━ Building ${TARGET_COUNT} targets ━━━${NC}"
echo ""

# Build results (simple files approach)
BUILD_RESULTS_DIR="/tmp/zigbuild-results-$$"
mkdir -p "$BUILD_RESULTS_DIR"

FAILED=0

# Build each target
for target in $TARGETS; do
    # Get friendly name
    case "$target" in
        x86_64-apple-darwin) name="macOS Intel" ;;
        aarch64-apple-darwin) name="macOS ARM (M1/M2/M3/M4)" ;;
        x86_64-unknown-linux-gnu) name="Linux x64 (GNU)" ;;
        x86_64-unknown-linux-musl) name="Linux x64 (musl/static)" ;;
        aarch64-unknown-linux-gnu) name="Linux ARM64 (GNU)" ;;
        aarch64-unknown-linux-musl) name="Linux ARM64 (musl/static)" ;;
        x86_64-pc-windows-gnu) name="Windows x64" ;;
        i686-pc-windows-gnu) name="Windows x86 (32-bit)" ;;
        *) name="$target" ;;
    esac
    
    echo "${YELLOW}🔨 Building $name ($target)...${NC}"
    
    if cargo zigbuild --release --target "$target" 2>&1 | grep -q "Finished"; then
        echo "${GREEN}✅ $name built successfully${NC}"
        echo "success" > "$BUILD_RESULTS_DIR/$target"
    else
        echo "${RED}❌ $name build failed${NC}"
        echo "failed" > "$BUILD_RESULTS_DIR/$target"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

# Create output directory
OUTPUT_DIR="dist"
mkdir -p "$OUTPUT_DIR"

echo "${BLUE}━━━ Copying binaries to ${OUTPUT_DIR}/ ━━━${NC}"
echo ""

# Copy and rename binaries
for target in $TARGETS; do
    if [ -f "$BUILD_RESULTS_DIR/$target" ] && [ "$(cat "$BUILD_RESULTS_DIR/$target")" = "success" ]; then
        # Get friendly name for filename
        case "$target" in
            x86_64-apple-darwin) short_name="macos-intel" ;;
            aarch64-apple-darwin) short_name="macos-arm" ;;
            x86_64-unknown-linux-gnu) short_name="linux-x64" ;;
            x86_64-unknown-linux-musl) short_name="linux-x64-musl" ;;
            aarch64-unknown-linux-gnu) short_name="linux-arm64" ;;
            aarch64-unknown-linux-musl) short_name="linux-arm64-musl" ;;
            x86_64-pc-windows-gnu) short_name="windows-x64" ;;
            i686-pc-windows-gnu) short_name="windows-x86" ;;
            *) short_name="$target" ;;
        esac
        
        # Determine source path
        case "$target" in
            *windows*)
                SRC="target/${target}/release/${BINARY_NAME}.exe"
                EXT=".exe"
                ;;
            *)
                SRC="target/${target}/release/${BINARY_NAME}"
                EXT=""
                ;;
        esac
        
        # Copy to dist with descriptive name
        DEST="${OUTPUT_DIR}/${BINARY_NAME}-${VERSION}-${short_name}${EXT}"
        
        if [ -f "$SRC" ]; then
            cp "$SRC" "$DEST"
            
            # Calculate size
            SIZE=$(du -h "$DEST" | cut -f1)
            echo "${GREEN}✅ ${short_name} → $(basename "$DEST") ($SIZE)${NC}"
            
            # Strip if not Windows and strip is available
            case "$target" in
                *windows*) ;;
                *)
                    if command -v strip >/dev/null 2>&1; then
                        strip "$DEST" 2>/dev/null || true
                    fi
                    ;;
            esac
        else
            echo "${RED}❌ ${short_name} binary not found at $SRC${NC}"
        fi
    fi
done

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Summary
if [ $FAILED -eq 0 ]; then
    echo "${GREEN}   ✨ All builds completed successfully! ✨${NC}"
else
    echo "${YELLOW}   ⚠️  ${FAILED} build(s) failed${NC}"
fi

echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "${GREEN}📊 Build Summary:${NC}"
for target in $TARGETS; do
    # Get friendly name
    case "$target" in
        x86_64-apple-darwin) name="macOS Intel" ;;
        aarch64-apple-darwin) name="macOS ARM" ;;
        x86_64-unknown-linux-gnu) name="Linux x64 (GNU)" ;;
        x86_64-unknown-linux-musl) name="Linux x64 (musl)" ;;
        aarch64-unknown-linux-gnu) name="Linux ARM64 (GNU)" ;;
        aarch64-unknown-linux-musl) name="Linux ARM64 (musl)" ;;
        x86_64-pc-windows-gnu) name="Windows x64" ;;
        i686-pc-windows-gnu) name="Windows x86" ;;
        *) name="$target" ;;
    esac
    
    if [ -f "$BUILD_RESULTS_DIR/$target" ]; then
        result=$(cat "$BUILD_RESULTS_DIR/$target")
        if [ "$result" = "success" ]; then
            echo "  ✅ $name ($target)"
        else
            echo "  ❌ $name ($target)"
        fi
    fi
done

echo ""
echo "${GREEN}📁 Output directory: ${OUTPUT_DIR}/${NC}"
ls -lh "$OUTPUT_DIR" 2>/dev/null || ls -l "$OUTPUT_DIR"

echo ""
echo "${GREEN}🚀 Next Steps:${NC}"
echo "  1. Test binaries on target platforms"
echo "  2. Create release archives: tar -czf archive.tar.gz dist/"
echo "  3. Upload to GitHub releases or package managers"
echo ""

# Create checksums
echo "${YELLOW}📝 Generating checksums...${NC}"
cd "$OUTPUT_DIR"

# Try different checksum commands
if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 * > SHA256SUMS 2>/dev/null || true
elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum * > SHA256SUMS 2>/dev/null || true
fi

if [ -f "SHA256SUMS" ]; then
    echo "${GREEN}✅ Checksums saved to ${OUTPUT_DIR}/SHA256SUMS${NC}"
    cat SHA256SUMS
else
    echo "${YELLOW}⚠️  Could not generate checksums${NC}"
fi

cd ..

# Cleanup
rm -rf "$BUILD_RESULTS_DIR"

echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}   Done! Happy shipping! 📦${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"