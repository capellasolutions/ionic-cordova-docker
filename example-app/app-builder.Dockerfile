FROM ubuntu:26.04
LABEL org.opencontainers.image.authors="Al-Mothafar Al-Hasan"
LABEL org.opencontainers.image.title="ionic-cordova-app-builder"
LABEL org.opencontainers.image.description="Toolchain image for building Ionic/Cordova Android apps (and preparing iOS)."

# -----------------------------------------------------------------------------
# General environment variables
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive

# cordova-android 15 needs a system Gradle (>= 8.4) on PATH to generate its Gradle
# wrapper; this var pins the wrapper's distribution to the same version we install below.
# NOTE: cordova-android 15 passes this straight to `gradle wrapper --gradle-distribution-url`,
# so it must be a plain URL — the old `https\:` properties-file escaping breaks Gradle's parser.
ARG GRADLE_VERSION
ENV GRADLE_VERSION=${GRADLE_VERSION:-8.14.5}
ENV CORDOVA_ANDROID_GRADLE_DISTRIBUTION_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip


# -----------------------------------------------------------------------------
# Install system basics
# -----------------------------------------------------------------------------
RUN \
  apt-get update -qqy && \
  apt-get install -qqy --no-install-recommends \
          apt-transport-https \
          ca-certificates \
          software-properties-common \
          gnupg \
          python3 \
          make \
          g++ \
          curl \
          expect \
          zip \
          unzip \
          libsass-dev \
          git \
          rsync \
          sudo


# -----------------------------------------------------------------------------
# Install Java
#
# cordova-android 13+ officially document JDK 17; the Android Gradle Plugin 8.x used
# by cordova-android 15 also runs on JDK 21 (with Gradle 8.5+), which is the newest LTS
# that works here. JDK 25 would need AGP 9 / Gradle 9.1+. Kept as an ARG so it can move.
# -----------------------------------------------------------------------------

ARG JAVA_VERSION
ENV JAVA_VERSION=${JAVA_VERSION:-21}

ENV JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64}

RUN apt-get update -qqy && \
  apt-get install -qqy --no-install-recommends openjdk-${JAVA_VERSION}-jdk


# -----------------------------------------------------------------------------
# Install Android / Android SDK / Android SDK elements
# -----------------------------------------------------------------------------

ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
# ANDROID_HOME is the modern name; keep it pointing at the same path for tooling that expects it.
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:/opt/tools

RUN \
  echo ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT} >> /etc/environment && \
  dpkg --add-architecture i386 && \
  apt-get update -qqy && \
  apt-get install -qqy --no-install-recommends \
          libc6-i386 \
          lib32stdc++6 \
          lib32gcc-s1 \
          lib32ncurses6 \
          lib32z1

# Check https://cordova.apache.org/docs/en/latest/guide/platforms/android/ first, and make sure you've the latest "cordova-android" in package.json
# And check <preference name="android-targetSdkVersion" value="X" /> in config.xml where X should same as ANDROID_PLATFORMS_VERSION
# cordova-android 15 requires SDK Platform 36 and Build Tools 36.0.0.
ARG ANDROID_PLATFORMS_VERSION
ENV ANDROID_PLATFORMS_VERSION=${ANDROID_PLATFORMS_VERSION:-36}

ARG ANDROID_SDK_TOOLS_VERSION
ENV ANDROID_SDK_TOOLS_LINK=https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION:-14742923}_latest.zip

ARG ANDROID_BUILD_TOOLS_VERSION
ENV ANDROID_BUILD_TOOLS_VERSION=${ANDROID_BUILD_TOOLS_VERSION:-36.0.0}

RUN \
  mkdir -p /root/.android && touch /root/.android/repositories.cfg  && \
  cd /opt && \
  curl -SLo sdk-tools-linux.zip ${ANDROID_SDK_TOOLS_LINK} && \
  unzip sdk-tools-linux.zip -d ${ANDROID_SDK_ROOT}/ && mkdir -p ${ANDROID_SDK_ROOT}/latest && \
  mv ${ANDROID_SDK_ROOT}/cmdline-tools/* ${ANDROID_SDK_ROOT}/latest && mv ${ANDROID_SDK_ROOT}/latest ${ANDROID_SDK_ROOT}/cmdline-tools/latest &&  \
  rm -f sdk-tools-linux.zip && chmod 775 ${ANDROID_SDK_ROOT} -R

RUN  yes | sdkmanager --update && yes | sdkmanager --licenses && \
  sdkmanager "platform-tools" && \
  sdkmanager "platforms;android-${ANDROID_PLATFORMS_VERSION}" && \
  sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# -----------------------------------------------------------------------------
# Install Gradle
#
# cordova-android 15 invokes a system `gradle` to generate the project's Gradle
# wrapper. Ubuntu's apt Gradle is far too old for the Android Gradle Plugin, so we
# install the official distribution and put it on PATH.
# -----------------------------------------------------------------------------
RUN curl -SLo /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
  unzip -q /tmp/gradle.zip -d /opt && \
  rm -f /tmp/gradle.zip && \
  ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle && \
  gradle --version

# -----------------------------------------------------------------------------
# Install Node & npm via NodeSource
#
# The old manual tarball + GPG verification relied on the SKS keyserver pool, which
# was permanently shut down in 2021 and made this image impossible to build. NodeSource
# ships a maintained apt repo with its own signing key.
# -----------------------------------------------------------------------------

ARG PACKAGE_MANAGER
ENV PACKAGE_MANAGER=${PACKAGE_MANAGER:-npm}

ARG NODE_VERSION
ENV NODE_VERSION=${NODE_VERSION:-24}

ENV NPM_CONFIG_LOGLEVEL=info

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -qqy --no-install-recommends nodejs && \
    node --version && \
    npm --version

# Yarn and pnpm are installed on demand with npm (which always ships with Node). We avoid
# Corepack on purpose: it is being unbundled from Node (25+), so relying on it would break
# the moment NODE_VERSION moves forward. Only the SELECTED manager is installed — npm builds
# (the default) add nothing extra, keeping the image smaller. Pick one per build via
# PACKAGE_MANAGER. This RUN executes as root, so the global install lands on the shared PATH
# and stays usable by the non-root build user created later.
ARG YARN_VERSION
ENV YARN_VERSION=${YARN_VERSION:-stable}

ARG PNPM_VERSION
ENV PNPM_VERSION=${PNPM_VERSION:-latest}

RUN if [ "${PACKAGE_MANAGER}" = "pnpm" ]; then \
      npm install -g pnpm@${PNPM_VERSION} && pnpm --version; \
    elif [ "${PACKAGE_MANAGER}" = "yarn" ]; then \
      npm install -g yarn@${YARN_VERSION} && yarn --version; \
    else \
      echo "Using npm bundled with Node; no extra package manager installed."; \
    fi

# -----------------------------------------------------------------------------
# Install Ruby + CocoaPods (used when preparing the iOS project)
# -----------------------------------------------------------------------------

RUN apt-get update && apt-get install -qqy --no-install-recommends ruby-full && \
    gem install bigdecimal etc && gem install cocoapods

# -----------------------------------------------------------------------------
# Clean up
# -----------------------------------------------------------------------------
RUN \
  apt-get clean && \
  apt-get autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# -----------------------------------------------------------------------------
# Create a non-root docker user to run this container
# -----------------------------------------------------------------------------

ARG USER
ENV USER=${USER:-ionic}

RUN \
  echo "create the build user" && \
  useradd --user-group --create-home --shell /bin/bash ${USER} && \
  echo "${USER}:${USER}" | chpasswd && \
  adduser ${USER} sudo && \
  \
  echo "create app/build dirs owned by the build user" && \
  mkdir /app && chown ${USER}:${USER} /app && chmod 775 /app && \
  mkdir /build && chown ${USER}:${USER} /build && chmod 775 /build && \
  \
  echo "image.config is written below as the build user" && \
  touch /image.config && chown ${USER}:${USER} /image.config && chmod 664 /image.config && \
  \
  echo "this is necessary for ionic commands to run" && \
  mkdir /home/${USER}/.ionic && chown ${USER}:${USER} /home/${USER}/.ionic && chmod 775 /home/${USER}/.ionic && \
  \
  echo "give the build user its own Android config dir (the SDK itself is world-readable via chmod 775 above)" && \
  mkdir -p /home/${USER}/.android && touch /home/${USER}/.android/repositories.cfg && \
  chown -R ${USER}:${USER} /home/${USER}/.android


# -----------------------------------------------------------------------------
# Switch the user of this image only now, because previous commands need to be
# run as root
# -----------------------------------------------------------------------------
USER ${USER}

ENV NPM_CONFIG_PREFIX=/home/${USER}/.npm-global
ENV PATH="/home/${USER}/.npm-global/bin:${PATH}"

# -----------------------------------------------------------------------------
# Install Global node modules
# -----------------------------------------------------------------------------

ARG CORDOVA_VERSION
ENV CORDOVA_VERSION=${CORDOVA_VERSION:-13.0.0}

ARG IONIC_CLI_VERSION
ENV IONIC_CLI_VERSION=${IONIC_CLI_VERSION:-7.2.1}

# The global CLIs are just executables on PATH, so install them with npm regardless of
# PACKAGE_MANAGER (npm is always present; Corepack's Yarn 4 has no `global add`).
# PACKAGE_MANAGER selects how the *app's* dependencies are installed, in the app Dockerfile.
RUN npm install -g cordova@"${CORDOVA_VERSION}" @angular/cli && \
    if [ -n "${IONIC_CLI_VERSION}" ]; then npm install -g @ionic/cli@"${IONIC_CLI_VERSION}"; fi && \
    npm cache clean --force


# -----------------------------------------------------------------------------
# Create the image.config file for the container to check the build
# configuration of this container later on
# -----------------------------------------------------------------------------
RUN { \
  echo "USER: ${USER}"; \
  echo "JAVA_VERSION: ${JAVA_VERSION}"; \
  echo "GRADLE_VERSION: ${GRADLE_VERSION}"; \
  echo "ANDROID_PLATFORMS_VERSION: ${ANDROID_PLATFORMS_VERSION}"; \
  echo "ANDROID_BUILD_TOOLS_VERSION: ${ANDROID_BUILD_TOOLS_VERSION}"; \
  echo "NODE_VERSION: ${NODE_VERSION}"; \
  echo "PACKAGE_MANAGER: ${PACKAGE_MANAGER}"; \
  echo "CORDOVA_VERSION: ${CORDOVA_VERSION}"; \
  echo "IONIC_CLI_VERSION: ${IONIC_CLI_VERSION}"; \
} >> /image.config && \
cat /image.config


# -----------------------------------------------------------------------------
# Just in case you are installing from private git repositories, enable git
# credentials
# -----------------------------------------------------------------------------
RUN git config --global credential.helper store

# -----------------------------------------------------------------------------
# WORKDIR is the generic /app folder. All volume mounts of the actual project
# code need to be put into /app.
# -----------------------------------------------------------------------------
WORKDIR /app
