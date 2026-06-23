ARG PLATFORM=android
FROM app-builder AS prepare-build

ARG USER
ARG ENV_NAME
ARG PACKAGE_ID
ARG VERSION
ARG PACKAGE_TYPE

# If arguments not specified then set a value
ENV USER=${USER:-ionic}
ENV ENV_NAME=${ENV_NAME:-dev}
ENV PACKAGE_ID=${PACKAGE_ID:-"com.example.com"}
ENV VERSION=${VERSION:-"MISSING"}
# Android artifact type: "bundle" (.aab for Google Play) or "apk" (installable on a device).
# Overrides the packageType in build.json so it can be chosen per build.
ENV PACKAGE_TYPE=${PACKAGE_TYPE:-bundle}

RUN echo "------------------------------------------"&& \
    echo "| BUILDING MOBILE APPLICATION             "&& \
    echo "| Environment: ${ENV_NAME}                "&& \
    echo "| Package: ${PACKAGE_ID}                  "&& \
    echo "| Version: ${VERSION}                     "&& \
    echo "------------------------------------------"

# Add package.json and lockfile first (before the rest of the project) so the
# dependency-install layer is cached and only re-runs when dependencies change.
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds
ADD --chown=ionic package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./

RUN sed -i "s/\"name\":.*/\"name\": \"${PACKAGE_ID}\",/g" ./package.json
# Uncomment if you want the version from Argument
#RUN sed -i "s/\"version\":.*/\"version\": \"${VERSION}\",/g" ./package.json

# PACKAGE_MANAGER is inherited from the app-builder image (selected there via
# --build-arg PACKAGE_MANAGER). yarn/pnpm use a clean, reproducible install when their
# lockfile is present; npm falls back to `install` if there's no package-lock.json yet.
RUN \
  if [ "${PACKAGE_MANAGER}" = "yarn" ]; then \
    yarn install --frozen-lockfile; \
  elif [ "${PACKAGE_MANAGER}" = "pnpm" ]; then \
    pnpm install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then \
    npm ci; \
  else \
    npm install; \
  fi

ADD --chown=ionic  . .

RUN sed -i "s/\(.*widget id=\)[^ ]*\( .*\)/\1\"${PACKAGE_ID}\"\2/" ./config.xml
# Uncomment if you want the version from Argument
#RUN sed -i "2s/\(.*version=\)[^ ]*\( .*\)/\1\"${VERSION}\"\2/" ./config.xml

USER ${USER}
RUN if [ "$ENV_NAME" = "prod" ]; \
    then \
      echo "Building Prod (No changes for environment and resources files)"; \
    else \
      cp /app/src/environments/environment.${ENV_NAME}.ts /app/src/environments/environment.prod.ts; \
      rsync -ar --info=progress2 ./resources/stage/ ./resources/ --exclude ./resources/stage/; \
      sed -i -e 's/<name>.*/\<name>My App Test<\/name>/g' ./config.xml; \
    fi

RUN cp /app/google-services/${ENV_NAME}-google-services.json  google-services.json; \
    cp /app/google-services/${ENV_NAME}-GoogleService-Info.plist  GoogleService-Info.plist;

FROM prepare-build AS build-android
RUN echo ">>> Building Android App <<<"
ENV BUILD_RESULT="Building Android App is done"

# Build the Angular web app first, then let Cordova package it. We call `cordova`
# directly instead of `ionic cordova build` because @ionic/angular-toolkit no longer
# ships the `cordova-build` Angular builder. The platform is added explicitly (it was
# removed by the `rm -rf` above), then `cordova build` copies the already-built ./www.
RUN rm -rf ./www ./platforms ./plugins && \
    npm run build -- --configuration=production && \
    cordova platform add android && \
    cordova build android --release --buildConfig=build.json --packageType=${PACKAGE_TYPE} -- -d && \
    mkdir -p ./output/android && \
    mv ./platforms/android/* ./output/android

FROM prepare-build AS build-ios
RUN echo ">>> Building iOS App <<<"
ENV BUILD_RESULT="Building iOS App is done"

# iOS cannot be compiled on Linux; we only prepare the Xcode project for a macOS runner to build.
RUN rm -rf ./www ./platforms ./plugins && \
    npm run build -- --configuration=production && \
    cordova platform add ios && \
    cordova prepare ios && \
    mkdir -p ./output/ios && \
    mv ./platforms/ios/* ./output/ios

FROM prepare-build AS build-all
RUN echo ">>> Building Android and then iOS Apps <<<"
ENV BUILD_RESULT="Building Android and then iOS Apps is done"

RUN rm -rf ./www ./platforms ./plugins && \
    npm run build -- --configuration=production && \
    cordova platform add android && \
    cordova build android --release --buildConfig=build.json --packageType=${PACKAGE_TYPE} -- -d && \
    mkdir -p ./output/android && \
    mv ./platforms/android/* ./output/android

RUN rm -rf ./platforms ./plugins && \
    cordova platform add ios && \
    cordova prepare ios && \
    mkdir -p ./output/ios && \
    mv ./platforms/ios/* ./output/ios

FROM build-${PLATFORM} AS final-build
RUN echo ">>> Yaay!! ${BUILD_RESULT} <<<"
