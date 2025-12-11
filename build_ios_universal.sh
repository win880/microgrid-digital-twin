#!/usr/bin/env bash
set -euo pipefail

# Snelle alternatieve build zonder XCFramework (fat static library)
# Werkt voor device (arm64) en simulator (arm64 + x86_64). Aan te raden is
# alsnog de XCFramework-route voor maximale compatibiliteit.

CRATE=ffi
OUT_DIR="ios/MicrogridApp/RustBridge"
HEADER_NAME="microgrid_ffi.h"
UNIVERSAL_LIB="$OUT_DIR/libmicrogrid.a"

# Targets toevoegen als ze ontbreken
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios-sim >/dev/null 2>&1 || true

# cbindgen installeren indien nodig (voor header)
if ! command -v cbindgen >/dev/null 2>&1; then
  cargo install cbindgen
fi

# Build voor device en beide simulator-architecturen
cargo build -p $CRATE --release --target aarch64-apple-ios
cargo build -p $CRATE --release --target aarch64-apple-ios-sim
cargo build -p $CRATE --release --target x86_64-apple-ios-sim

# Output map voor Xcode artefacten
mkdir -p "$OUT_DIR"

# Header genereren
cbindgen core/ffi -o "$OUT_DIR/$HEADER_NAME"
echo "Header generated: $OUT_DIR/$HEADER_NAME"

# Universele (fat) static library maken met device + simulator slices
lipo -create   target/aarch64-apple-ios/release/lib${CRATE}.a   target/aarch64-apple-ios-sim/release/lib${CRATE}.a   target/x86_64-apple-ios-sim/release/lib${CRATE}.a   -output "$UNIVERSAL_LIB"

echo "Universal static lib: $UNIVERSAL_LIB"
echo "Koppel dit bestand en de header in Xcode (Do Not Embed)."
