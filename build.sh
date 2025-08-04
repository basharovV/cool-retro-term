#!/bin/bash
set -euo pipefail
rm -rf cool-retro-term.app
# Detect Homebrew Qt5 path dynamically
QT_PATH="$(brew --prefix qt@5 2>/dev/null || echo "")"
if [[ -z "$QT_PATH" ]]; then
  echo "Error: qt@5 is not installed via Homebrew."
  exit 1
fi

QMAKE="$QT_PATH/bin/qmake"

if [[ ! -x "$QMAKE" ]]; then
  echo "Error: qmake not found or not executable at $QMAKE"
  exit 1
fi

echo "Using qmake at: $QMAKE"

# Clean build artifacts (adjust patterns as needed)
echo "Cleaning old build files..."
find . -name Makefile -exec rm -f {} +
find . -name '*.o' -exec rm -f {} +
find . -name '*.d' -exec rm -f {} +
find . -name '*.so' -exec rm -f {} +
find . -name '*.dylib' -exec rm -f {} +

# Run qmake with arm64 arch, release config
echo "Running qmake for arm64 release build..."
"$QMAKE" QMAKE_MAC_ARCHS=arm64 -config release

# Run make with parallel jobs = number of CPU cores
JOBS=$(sysctl -n hw.ncpu)
echo "Building with make -j$JOBS ..."
make -j"$JOBS"

# Copy the required dependencies in to the app
mkdir cool-retro-term.app/Contents/PlugIns
cp -r qmltermwidget/QMLTermWidget cool-retro-term.app/Contents/PlugIns

# TODO: Inject environment variables into the app - Make sure LC_CTYPE is set to UTF-8
# Right now to get UTF-8 support, we're relying on a system wide workaround via launchctl load:
# launchctl load -w /Library/LaunchDaemons/setenv.LC_CTYPE.plist

# Copy to Applications, replace existing
cp -rf cool-retro-term.app /Applications

echo "Build complete!"
