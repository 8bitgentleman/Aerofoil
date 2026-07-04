#!/usr/bin/env bash
#
# Linux/macOS equivalent of remove_symlinks.bat.
# Removes the native-source symlinks created by make_symlinks.sh.

set -euo pipefail

cd "$(dirname "$0")"

for link in AerofoilSDL AerofoilPortable Common SDL2 GpApp GpShell GpCommon \
            PortabilityLayer rapidjson MacRomanConversion stb; do
    [ -L "app/jni/$link" ] && rm -f "app/jni/$link"
done

# Repo-root SDL2 alias created by make_symlinks.sh.
[ -L "../SDL2" ] && rm -f "../SDL2"

exit 0
