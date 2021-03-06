FROM openjdk:8

LABEL Description="This image provides a base Android development environment for ionic3, and may be used to run tests."
LABEL maintainer="Nickbing Lao <giscafer@outlook.com>"

# set default build arguments
ARG SDK_VERSION=sdk-tools-linux-3859397.zip
ARG ANDROID_BUILD_VERSION=26
ARG ANDROID_TOOLS_VERSION=26.0.0
ARG BUCK_VERSION=2019.06.18.01
ARG NDK_VERSION=17c
ARG WATCHMAN_VERSION=4.9.0

# set default environment variables
ENV ADB_INSTALL_TIMEOUT=10
ENV PATH=${PATH}:/opt/buck/bin/
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ENV ANDROID_NDK=/opt/ndk/android-ndk-r$NDK_VERSION
ENV PATH=${PATH}:${ANDROID_NDK}
ENV GRADLE_HOME=/opt/gradle
ENV PATH=${PATH}:${GRADLE_HOME}

# install system dependencies
RUN apt-get update -qq && apt-get install -qq -y --no-install-recommends \
    apt-transport-https \
    curl \
    build-essential \
    file \
    git \
    gnupg2 \
    python \
    unzip \
    && rm -rf /var/lib/apt/lists/*;

# install nodejs and yarn packages from nodesource and yarn apt sources
RUN echo "deb https://deb.nodesource.com/node_10.x stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends nodejs yarn \
    && rm -rf /var/lib/apt/lists/*

# download and unpack NDK
RUN curl -sS https://dl.google.com/android/repository/android-ndk-r$NDK_VERSION-linux-x86_64.zip -o /tmp/ndk.zip \
    && mkdir /opt/ndk \
    && unzip -q -d /opt/ndk /tmp/ndk.zip \
    && rm /tmp/ndk.zip

# download and install buck using debian package
RUN curl -sS -L https://github.com/facebook/buck/releases/download/v${BUCK_VERSION}/buck.${BUCK_VERSION}_all.deb -o /tmp/buck.deb \
    && dpkg -i /tmp/buck.deb \
    && rm /tmp/buck.deb

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN curl -sS https://dl.google.com/android/repository/${SDK_VERSION} -o /tmp/sdk.zip \
    && mkdir /opt/android \
    && unzip -q -d /opt/android /tmp/sdk.zip \
    && rm /tmp/sdk.zip

# Add android SDK tools
RUN yes | sdkmanager --licenses && sdkmanager --update
RUN sdkmanager "system-images;android-19;google_apis;armeabi-v7a" \
    "platform-tools" \
    "platforms;android-$ANDROID_BUILD_VERSION" \
    "build-tools;$ANDROID_TOOLS_VERSION" \
    "add-ons;addon-google_apis-google-23" \
    "extras;android;m2repository"


# Install Cordova and Ionic
RUN sudo npm update -g  \
    && sudo npm install -g ionic@3.9.0 cordova@7.1.0  \
    && cordova telemetry off  \
    && CI=true ionic config set -g daemon.updates false  \
    && ionic config set -g telemetry false 

# Install Gradle
ARG GRADLE_VERSION=4.10.2
RUN sudo curl https://downloads.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip > /tmp/gradle-$GRADLE_VERSION-bin.zip \
    && sudo unzip /tmp/gradle-$GRADLE_VERSION-bin.zip -d /tmp && rm /tmp/gradle-$GRADLE_VERSION-bin.zip \
    && sudo mv /tmp/gradle-$GRADLE_VERSION /opt/gradle \
    && PATH="/opt/gradle/bin:${PATH}" 

# clean up unnecessary directories
RUN rm -rf /opt/android/.android



