#!/bin/bash

set -e

docker build . -f ./app-builder.Dockerfile -t app-builder
#docker push app-builder

version="0.0.0"
platform="all"
PS3="Select platform to build: "
plt_options=("Android" "iOS" "All")
invalid_opt="\n${COLOR_LIGHT_RED}Invalid option. Try another one.${COLOR_NC}\n"

select opt in "${plt_options[@]}" "Quit"; do
  case "$REPLY" in
  1)
    # shellcheck disable=SC2059
    printf "\n${COLOR_LIGHT_CYAN}You picked to build [${COLOR_GREEN}${opt}${COLOR_LIGHT_CYAN}] platform app ${COLOR_NC}\n\n"
    platform="android"
    break
    ;;
  2)
    # shellcheck disable=SC2059
    printf "\n${COLOR_LIGHT_CYAN}You picked to build [${COLOR_LIGHT_PURPLE}${opt}${COLOR_LIGHT_CYAN}] platform app ${COLOR_NC}\n\n"
    platform="ios"
    break
    ;;
  3)
    # shellcheck disable=SC2059
    printf "\n${COLOR_LIGHT_CYAN}You picked to build [${COLOR_LIGHT_PURPLE}${opt}${COLOR_LIGHT_CYAN}] platforms apps ${COLOR_NC}\n\n"
    platform="all"
    break
    ;;
  $((${#plt_options[@]} + 1)))
    printf "Quitting execution"
    exit
    ;;
  *)
    # shellcheck disable=SC2059
    printf "${invalid_opt}"
    continue
    ;;
  esac
done

cur_dir=$(pwd)

docker build . \
  --build-arg ENV_NAME="${ENV_NAME}" \
  --build-arg PACKAGE_ID="${PACKAGE_ID}" \
  --build-arg PLATFORM=${platform} \
  --build-arg VERSION="${version}" \
  -f ./Dockerfile \
  -t app-build

if [[ "$platform" == "android" || "$platform" == "all" ]]
then
  echo "Copying generated Android build to build-output/android"
  docker run --user root:root --privileged=true -v "$cur_dir"/build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/android /app/mount
fi

if [[ "$platform" == "ios" || "$platform" == "all" ]]
then
  echo "Copying generated iOS build to build-output/ios"
  docker run --user root:root --privileged=true -v "$cur_dir"/build-output:/app/mount:Z --rm --entrypoint cp app-build -r ./output/ios /app/mount
  cd "$cur_dir"/build-output/ios && pod repo update && pod install
fi
