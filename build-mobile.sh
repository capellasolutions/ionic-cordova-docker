#!/bin/bash
#
# Build the Ionic/Cordova app inside Docker and copy the artifacts to ./build-output.
#
# Run this from the root of your Ionic project (the folder that contains package.json).
# The repo root is only a template; to try the pipeline use: cd example-app && ./build-mobile.sh
#
# Usage:
#   ./build-mobile.sh [android|ios|all]
# With no argument an interactive menu is shown.
#
# Configurable via environment, e.g.:
#   ENV_NAME=dev PACKAGE_ID=com.acme.app PACKAGE_MANAGER=yarn ./build-mobile.sh android
#   PACKAGE_TYPE=apk ./build-mobile.sh android   # installable .apk instead of a Play .aab

set -euo pipefail

# --- Colors (fall back to empty strings when output is not a terminal) --------
if [ -t 1 ]; then
  COLOR_NC=$'\033[0m'
  COLOR_GREEN=$'\033[0;32m'
  COLOR_LIGHT_RED=$'\033[1;31m'
  COLOR_LIGHT_CYAN=$'\033[1;36m'
  COLOR_LIGHT_PURPLE=$'\033[1;35m'
else
  COLOR_NC='' COLOR_GREEN='' COLOR_LIGHT_RED='' COLOR_LIGHT_CYAN='' COLOR_LIGHT_PURPLE=''
fi

# --- Sanity check: must run from an Ionic project root ------------------------
if [ ! -f package.json ]; then
  printf "%bERROR:%b no package.json found in %s\n" "$COLOR_LIGHT_RED" "$COLOR_NC" "$(pwd)" >&2
  printf "Run this from the root of your Ionic project (try: cd example-app && ./build-mobile.sh)\n" >&2
  exit 1
fi

# --- Configuration (override any of these via the environment) ---------------
version="${VERSION:-0.0.1}"
ENV_NAME="${ENV_NAME:-prod}"
PACKAGE_ID="${PACKAGE_ID:-com.example.app}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-npm}"
PACKAGE_TYPE="${PACKAGE_TYPE:-bundle}"   # Android: "bundle" (.aab) or "apk"
platform="all"

# Validate the values that get forwarded straight into the build (fail fast with a
# clear message instead of a cryptic error deep inside the Docker build).
case "$PACKAGE_TYPE" in
  bundle | apk) ;;
  *)
    printf "%bInvalid PACKAGE_TYPE '%s'.%b Use: bundle | apk\n" \
      "$COLOR_LIGHT_RED" "$PACKAGE_TYPE" "$COLOR_NC" >&2
    exit 1
    ;;
esac
case "$PACKAGE_MANAGER" in
  npm | yarn | pnpm) ;;
  *)
    printf "%bInvalid PACKAGE_MANAGER '%s'.%b Use: npm | yarn | pnpm\n" \
      "$COLOR_LIGHT_RED" "$PACKAGE_MANAGER" "$COLOR_NC" >&2
    exit 1
    ;;
esac

# --- Build the toolchain base image ------------------------------------------
# This image is heavy but cached; you can comment this line out after the first
# successful build to save time.
docker build . -f ./app-builder.Dockerfile \
  --build-arg PACKAGE_MANAGER="${PACKAGE_MANAGER}" \
  -t app-builder
# Only needed if you distribute the builder image to a registry — and then you
# must tag it with your registry host, e.g. docker push registry.example.com/app-builder
#docker push app-builder

# --- Platform selection ------------------------------------------------------
case "${1:-}" in
  android | ios | all)
    platform="$1"
    printf "%bBuilding [%b%s%b] platform app%b\n\n" \
      "$COLOR_LIGHT_CYAN" "$COLOR_GREEN" "$platform" "$COLOR_LIGHT_CYAN" "$COLOR_NC"
    ;;
  "")
    PS3="Select platform to build: "
    select opt in "Android" "iOS" "All" "Quit"; do
      case "$REPLY" in
        1) platform="android"; break ;;
        2) platform="ios";     break ;;
        3) platform="all";     break ;;
        4) printf "Quitting execution\n"; exit 0 ;;
        *) printf "%bInvalid option. Try another one.%b\n" "$COLOR_LIGHT_RED" "$COLOR_NC" ;;
      esac
    done
    ;;
  *)
    printf "%bUnknown platform '%s'.%b Use: android | ios | all\n" \
      "$COLOR_LIGHT_RED" "$1" "$COLOR_NC" >&2
    exit 1
    ;;
esac

cur_dir=$(pwd)
mkdir -p "$cur_dir/build-output"

# --- Build the app image -----------------------------------------------------
docker build . \
  --build-arg ENV_NAME="${ENV_NAME}" \
  --build-arg PACKAGE_ID="${PACKAGE_ID}" \
  --build-arg PACKAGE_MANAGER="${PACKAGE_MANAGER}" \
  --build-arg PACKAGE_TYPE="${PACKAGE_TYPE}" \
  --build-arg PLATFORM="${platform}" \
  --build-arg VERSION="${version}" \
  -f ./Dockerfile \
  -t app-build

# --- Copy the artifacts out of the image -------------------------------------
if [ "$platform" = "android" ] || [ "$platform" = "all" ]; then
  echo "Copying generated Android build to build-output/android"
  docker run --user root:root -v "$cur_dir"/build-output:/app/mount:Z --rm \
    --entrypoint cp app-build -r ./output/android /app/mount
fi

if [ "$platform" = "ios" ] || [ "$platform" = "all" ]; then
  echo "Copying generated iOS build to build-output/ios"
  docker run --user root:root -v "$cur_dir"/build-output:/app/mount:Z --rm \
    --entrypoint cp app-build -r ./output/ios /app/mount
  # iOS can only be *prepared* on Linux; finish the build on macOS. The Xcode project (and any Pods its plugins need) was
  # already generated inside the Docker image, so this host-side 'pod install' is only a convenience to refresh Pods on a
  # macOS machine — it is safely skipped when CocoaPods isn't present here. This is informational, not an error.
  if command -v pod >/dev/null 2>&1; then
    cd "$cur_dir"/build-output/ios && pod repo update && pod install
  else
    echo "iOS project already prepared inside Docker. Skipping the host 'pod install' (no CocoaPods here; it is only needed to refresh Pods on macOS)."
  fi
fi
