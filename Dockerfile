FROM ubuntu:18.04
MAINTAINER Al-Mothafar Al-Hasan

# -----------------------------------------------------------------------------
# General environment variables
# -----------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive


# -----------------------------------------------------------------------------
# Install system basics
# -----------------------------------------------------------------------------
RUN \
  apt-get update -qqy && \
  apt-get install -qqy --allow-unauthenticated \
          apt-transport-https \
          software-properties-common \
          python \
          make \
          g++ \
          curl \
          expect \
          zip \
          libsass-dev \
          git \
          sudo


# -----------------------------------------------------------------------------
# Install Java
# -----------------------------------------------------------------------------
ARG JAVA_VERSION
ENV JAVA_VERSION ${JAVA_VERSION:-8}

ENV JAVA_HOME ${JAVA_HOME:-/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64}
# For JDK 9 and JDK 10 uncomment the following
#ENV JAVA_OPTS '-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'

RUN add-apt-repository ppa:openjdk-r/ppa -y && \
  apt-get update -qqy && \
  apt-get install openjdk-${JAVA_VERSION}-jdk -qqy


# -----------------------------------------------------------------------------
# Install Android / Android SDK / Android SDK elements
# -----------------------------------------------------------------------------

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:/opt/tools

# Check https://cordova.apache.org/docs/en/latest/guide/platforms/android/ first, and make sure you've the latest "cordova-android" in package.json
ARG ANDROID_PLATFORMS_VERSION
ENV ANDROID_PLATFORMS_VERSION ${ANDROID_PLATFORMS_VERSION:-28}

ARG ANDROID_BUILD_TOOLS_VERSION
ENV ANDROID_BUILD_TOOLS_VERSION ${ANDROID_BUILD_TOOLS_VERSION:-29.0.2}

RUN \
  echo ANDROID_HOME=${ANDROID_HOME} >> /etc/environment && \
  dpkg --add-architecture i386 && \
  apt-get update -qqy && \
  apt-get install -qqy --allow-unauthenticated\
          gradle  \
          libc6-i386 \
          lib32stdc++6 \
          lib32gcc1 \
          lib32ncurses5 \
          lib32z1 \
          qemu-kvm \
          kmod && \
  mkdir -p /root/.android && touch /root/.android/repositories.cfg  && \
  cd /opt && \
  curl -SLo sdk-tools-linux.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
  unzip sdk-tools-linux.zip -d ${ANDROID_HOME} && rm -f sdk-tools-linux.zip && chmod 775 ${ANDROID_HOME} -R && \
  yes | sdkmanager --update  && yes | sdkmanager --licenses && \
  sdkmanager "tools" && \
  sdkmanager "platform-tools" && \
  sdkmanager "platforms;android-${ANDROID_PLATFORMS_VERSION}" && \
  sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# -----------------------------------------------------------------------------
# Install Node, NPM, yarn
# -----------------------------------------------------------------------------
ARG NODE_VERSION
ENV NODE_VERSION ${NODE_VERSION:-12.10.0}

ARG NPM_VERSION
ENV NPM_VERSION ${NPM_VERSION:-6.11.3}

ARG PACKAGE_MANAGER
ENV PACKAGE_MANAGER ${PACKAGE_MANAGER:-npm}

ENV NPM_CONFIG_LOGLEVEL info

RUN buildDeps='xz-utils' \
    && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
     amd64) ARCH='x64';; \
     ppc64el) ARCH='ppc64le';; \
     s390x) ARCH='s390x';; \
     arm64) ARCH='arm64';; \
     armhf) ARCH='armv7l';; \
     i386) ARCH='x86';; \
     *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    # gpg keys listed at https://github.com/nodejs/node#release-keys
    && set -ex \
    && for key in \
     94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
     FD3A5288F042B6850C66B31F09FE44734EB7990E \
     71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
     DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
     C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
     B9AE9905FFD7803F25714661B63B535A4C206CA9 \
     77984A986EBC2AA786BC0F66B01FBB92821C587A \
     8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
     4ED778F539E3634C779C87C6D7062848A1AB005C \
     A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
     B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
     gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
     gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
     gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.17.3

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz

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
ENV USER ${USER:-ionic}

RUN \
  echo "create user with appropriate rights, groups and permissions" && \
  useradd --user-group --create-home --shell /bin/false ${USER} && \
  echo "${USER}:${USER}" | chpasswd && \
  adduser ${USER} sudo && \
  adduser ${USER} root && \
  chmod 775 / && \
  usermod -a -G root ${USER} && \
  \
  echo "create the file and set permissions now with root user" && \
  mkdir /app && chown ${USER}:${USER} /app && chmod 775 /app && \
  mkdir /build && chown ${USER}:${USER} /build && chmod 775 /build && \
  \
  echo "create the file and set permissions now with root user" && \
  touch /image.config && chown ${USER}:${USER} /image.config && chmod 775 /image.config && \
  \
  echo "this is necessary for ionic commands to run" && \
  mkdir /home/${USER}/.ionic && chown ${USER}:${USER} /home/${USER}/.ionic && chmod 775 /home/${USER}/.ionic && \
  \
  echo "this is necessary to install global npm modules" && \
  chown ${USER}:${USER} /usr/local/bin
  #&& chown ${USER}:${USER} ${ANDROID_HOME} -R


# -----------------------------------------------------------------------------
# Copy start.sh and set permissions
# -----------------------------------------------------------------------------
COPY start.sh /start.sh
RUN chown ${USER}:${USER} /start.sh && chmod 644 /start.sh


# -----------------------------------------------------------------------------
# Switch the user of this image only now, because previous commands need to be
# run as root
# -----------------------------------------------------------------------------
USER ${USER}

ENV NPM_CONFIG_PREFIX=/home/${USER}/.npm-global

# -----------------------------------------------------------------------------
# Install Global node modules
# -----------------------------------------------------------------------------

ARG CORDOVA_VERSION
ENV CORDOVA_VERSION ${CORDOVA_VERSION:-9.0.0}

ARG IONIC_VERSION
ENV IONIC_VERSION ${IONIC_VERSION:-5.4.1}

ARG TYPESCRIPT_VERSION
ENV TYPESCRIPT_VERSION ${TYPESCRIPT_VERSION:-3.5.3}

RUN \
  if [ "${PACKAGE_MANAGER}" != "yarn" ]; then \
    export PACKAGE_MANAGER="npm" && \
    npm install -g cordova@"${CORDOVA_VERSION}" cordova-check-plugins @angular/cli && \
    if [ -n "${IONIC_VERSION}" ]; then npm install -g ionic@"${IONIC_VERSION}"; fi && \
    if [ -n "${TYPESCRIPT_VERSION}" ]; then npm install -g typescript@"${TYPESCRIPT_VERSION}"; fi \
  else \
    yarn global add cordova@"${CORDOVA_VERSION}" && \
    yarn global add cordova-check-plugins && \
    yarn global add @angular/cli && \
    if [ -n "${IONIC_VERSION}" ]; then yarn global add ionic@"${IONIC_VERSION}"; fi && \
    if [ -n "${TYPESCRIPT_VERSION}" ]; then yarn global add typescript@"${TYPESCRIPT_VERSION}"; fi \
  fi && \
  ${PACKAGE_MANAGER} cache clean --force


# -----------------------------------------------------------------------------
# Create the image.config file for the container to check the build
# configuration of this container later on
# -----------------------------------------------------------------------------
RUN \
echo "USER: ${USER}\n\
JAVA_VERSION: ${JAVA_VERSION}\n\
ANDROID_PLATFORMS_VERSION: ${ANDROID_PLATFORMS_VERSION}\n\
ANDROID_BUILD_TOOLS_VERSION: ${ANDROID_BUILD_TOOLS_VERSION}\n\
NODE_VERSION: ${NODE_VERSION}\n\
NPM_VERSION: ${NPM_VERSION}\n\
PACKAGE_MANAGER: ${PACKAGE_MANAGER}\n\
CORDOVA_VERSION: ${CORDOVA_VERSION}\n\
IONIC_VERSION: ${IONIC_VERSION}\n\
TYPESCRIPT_VERSION: ${TYPESCRIPT_VERSION}\n\
GULP_VERSION: ${GULP_VERSION:-none}\n\
" >> /image.config && \
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

USER root

ADD *.json ./
ADD config.xml .
RUN npm config set -g production false && \
    chown -R ${USER}:${USER} /app
RUN apt-get update -qqy && \
  apt-get install -qqy --allow-unauthenticated \
    rsync && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ${USER}

ENV NPM_CONFIG_PREFIX=/home/${USER}/.npm-global
ENV PATH="/home/${USER}/.npm-global/bin:${PATH}"

RUN npm install
RUN npm rebuild node-sass --force
# -----------------------------------------------------------------------------
# The script start.sh installs package.json and puts a watch on it. This makes
# sure that the project has allways the latest dependencies installed.
# -----------------------------------------------------------------------------

RUN ${PACKAGE_MANAGER} cache clean --force

#ADD --chown=ionic  . .
#ENTRYPOINT ["/start.sh"]


# -----------------------------------------------------------------------------
# After /start.sh the bash is called.
# -----------------------------------------------------------------------------
CMD ["ionic", "serve", "-b", "-p", "8100", "--external"]
