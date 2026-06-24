#!/usr/bin/env bash
set -euo pipefail

TARGET="aarch64-unknown-linux-gnu"
BINARY="target/${TARGET}/release/led-controller"
DEPLOY=""
FEATURES="hardware"

usage() {
    echo "Usage: $0 [--target <triple>] [--no-hardware] [--deploy user@host]"
    echo ""
    echo "  --target <triple>    Rust target triple (default: aarch64-unknown-linux-gnu)"
    echo "  --no-hardware        Build without the hardware feature (NullPixels)"
    echo "  --deploy user@host   SCP the binary to the Pi after building"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --target armv7-unknown-linux-gnueabihf"
    echo "  $0 --deploy pi@raspberrypi.local"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --target)   TARGET="$2"; shift 2 ;;
        --no-hardware) FEATURES=""; shift ;;
        --deploy)   DEPLOY="$2"; shift 2 ;;
        -h|--help)  usage ;;
        *)          echo "Unknown option: $1"; usage ;;
    esac
done

BINARY="target/${TARGET}/release/led-controller"

# Check dependencies
if ! command -v cross &>/dev/null; then
    echo "error: 'cross' is not installed. Run: cargo install cross"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "error: Docker is not running. cross requires Docker."
    exit 1
fi

# Add target if not already installed
rustup target add "$TARGET"

# Build
echo "Building for ${TARGET}..."
if [[ -n "$FEATURES" ]]; then
    cross build --release --features "$FEATURES" --target "$TARGET"
else
    cross build --release --target "$TARGET"
fi

echo ""
echo "Built: ${BINARY} ($(du -sh "$BINARY" | cut -f1))"

# Deploy
if [[ -n "$DEPLOY" ]]; then
    echo "Deploying to ${DEPLOY}..."
    scp "$BINARY" "${DEPLOY}:~/led-controller"
    echo "Deployed to ${DEPLOY}:~/led-controller"
    echo ""
    echo "To run on the Pi:"
    echo "  ssh ${DEPLOY} 'sudo ~/led-controller'"
fi
