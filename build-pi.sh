#!/usr/bin/env bash
set -euo pipefail

TARGET="aarch64-unknown-linux-gnu"
DEPLOY=""
FEATURES="hardware"
APP_ARGS=()

usage() {
    echo "Usage: $0 [--target <triple>] [--no-hardware] [--deploy user@host] [-- <app flags>]"
    echo ""
    echo "  --target <triple>    Rust target triple (default: aarch64-unknown-linux-gnu)"
    echo "  --no-hardware        Build without the hardware feature (NullPixels)"
    echo "  --deploy user@host   SCP the binary to the Pi after building"
    echo "  -- <app flags>       Flags passed through to the binary (see below)"
    echo ""
    echo "App flags (passed after --):"
    echo "  --pixels <n>         Number of LEDs in the strip [default: 60]"
    echo "  --gpio-pin <n>       GPIO pin number [default: 18]"
    echo "  --brightness <n>     LED brightness 0-255 [default: 25]"
    echo "  --port <n>           Port to listen on [default: 3000]"
    echo "  --fade-in-ms <n>     Fade-in duration in milliseconds [default: 3000]"
    echo "  --fade-out-ms <n>    Fade-out duration in milliseconds [default: 3000]"
    echo "  --crossfade-ms <n>   Crossfade duration in milliseconds [default: 3000]"
    echo ""
    echo "Examples:"
    echo "  $0 --deploy pi@raspberrypi.local"
    echo "  $0 --deploy pi@raspberrypi.local -- --pixels 144 --brightness 80"
    echo "  $0 --target armv7-unknown-linux-gnueabihf --deploy pi@raspberrypi.local -- --port 8080"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --target)      TARGET="$2"; shift 2 ;;
        --no-hardware) FEATURES=""; shift ;;
        --deploy)      DEPLOY="$2"; shift 2 ;;
        -h|--help)     usage ;;
        --)            shift; APP_ARGS=("$@"); break ;;
        *)             echo "Unknown option: $1"; usage ;;
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
    if [[ ${#APP_ARGS[@]} -gt 0 ]]; then
        echo "  ssh ${DEPLOY} 'sudo ~/led-controller ${APP_ARGS[*]}'"
    else
        echo "  ssh ${DEPLOY} 'sudo ~/led-controller'"
    fi
fi
