#!/usr/bin/env bash
#
# Linux/macOS equivalent of make_symlinks.bat.
#
# The native source tree is not vendored under app/jni/ directly; it is
# assembled from sibling directories in the repo root via symlinks. On Windows
# these are created with `mklink /D` (see make_symlinks.bat). This script does
# the same with `ln -s` so the ndkBuild-based native build works on Linux/CI.
#
# Note on the repo-root SDL2 symlink: several module Android.mk files reference
# SDL via a relative "../SDL2/include" path. On Windows "../" is collapsed
# lexically, so it stays inside app/jni and resolves through app/jni/SDL2. On
# POSIX, "../" from a *symlinked* directory is resolved physically and escapes
# to the real repo root, where the SDL tree is named "SDL2-2.30.5" rather than
# "SDL2". The repo-root "SDL2 -> SDL2-2.30.5" symlink makes those references
# resolve on Linux/macOS. Keep it in sync with the SDL version in the tree.

set -euo pipefail

cd "$(dirname "$0")"

# Version-specific SDL directory that lives in the repo root.
SDL_DIR="SDL2-2.30.5"

"$(dirname "$0")/remove_symlinks.sh"

# Per-module symlinks under app/jni (targets are three levels up, in repo root).
ln -sfn ../../../AerofoilSDL        app/jni/AerofoilSDL
ln -sfn ../../../AerofoilPortable   app/jni/AerofoilPortable
ln -sfn ../../../Common             app/jni/Common
ln -sfn "../../../${SDL_DIR}"       app/jni/SDL2
ln -sfn ../../../GpApp              app/jni/GpApp
ln -sfn ../../../GpShell            app/jni/GpShell
ln -sfn ../../../GpCommon           app/jni/GpCommon
ln -sfn ../../../PortabilityLayer   app/jni/PortabilityLayer
ln -sfn ../../../rapidjson          app/jni/rapidjson
ln -sfn ../../../MacRomanConversion app/jni/MacRomanConversion
ln -sfn ../../../stb                app/jni/stb

# Repo-root alias so cross-module "../SDL2/include" references resolve on POSIX.
ln -sfn "${SDL_DIR}" ../SDL2

echo "Symlinks created."
