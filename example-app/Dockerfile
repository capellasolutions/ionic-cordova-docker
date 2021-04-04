ARG PLATFORM
FROM app-builder AS prepare-build

ARG USER
ARG ENV_NAME
ARG PACKAGE_ID
ARG VERSION

# If arguments not sepcified then set a value
ENV USER ${USER:-ionic}
ENV ENV_NAME ${ENV_NAME:-dev}
ENV PACKAGE_ID ${PACKAGE_ID:-"com.example.com"}
ENV VERSION ${VERSION:-"MISSING"}

RUN echo "------------------------------------------"&& \
    echo "| BUILDING MOBILE APPLICATION             "&& \
    echo "| Environment: ${ENV_NAME}                "&& \
    echo "| Package: ${PACKAGE_ID}                  "&& \
    echo "| Version: ${VERSION}                     "&& \
    echo "------------------------------------------"

# So you add each file? the you add all, what is the point?
# adding package.json and package-lock.json first, and then adding entire project, it helps us to get benefit from "Docker Cache"
#  see this link for more info:
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#use-multi-stage-builds
ADD --chown=ionic *.json ./

RUN sed -i "s/\"name\":.*/\"name\": \"${PACKAGE_ID}\",/g" ./package.json
# Uncomment if you want the version from Argument
#RUN sed -i "s/\"version\":.*/\"version\": \"${VERSION}\",/g" ./package.json

RUN npm install --force

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
ENV BUILD_RESULT "Building Android App is done"

RUN rm -rf ./www ./platforms ./plugins && \
    ionic cordova build android --no-interactive --confirm --prod --aot --minifyjs --minifycss --optimizejs --release --buildConfig=build.json -- -d &&\
    mkdir -p ./output/android && \
    mv ./platforms/android/* ./output/android

FROM prepare-build AS build-ios
RUN echo ">>> Building iOS App <<<"
ENV BUILD_RESULT "Building iOS App is done"

RUN rm -rf ./www ./platforms ./plugins && \
    ionic cordova prepare ios --no-interactive --confirm --prod --aot --minifyjs --minifycss --optimizejs --release --buildConfig=build.json -- -d &&\
    mkdir -p ./output/ios && \
    mv ./platforms/ios/* ./output/ios

FROM prepare-build AS build-all
RUN echo ">>> Building Android and then iOS Apps <<<"
ENV BUILD_RESULT "Building Android and then iOS Apps is done"

RUN rm -rf ./www ./platforms ./plugins && \
    ionic cordova build android --no-interactive --confirm --prod --aot --minifyjs --minifycss --optimizejs --release --buildConfig=build.json -- -d &&\
    mkdir -p ./output/android && \
    mv ./platforms/android/* ./output/android

RUN rm -rf ./www ./platforms ./plugins && \
    ionic cordova prepare ios --no-interactive --confirm --prod --aot --minifyjs --minifycss --optimizejs --release --buildConfig=build.json -- -d &&\
    mkdir -p ./output/ios && \
    mv ./platforms/ios/* ./output/ios

FROM build-${PLATFORM} AS final-build
RUN echo ">>> Yaay!! ${BUILD_RESULT} <<<"
