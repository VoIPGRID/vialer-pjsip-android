FROM debian
MAINTAINER "hello@wearespindle.com"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM='xterm-256color'

# Install necessary packages
RUN apt-get update && \
    apt-get install -yq curl swig bzip2 gcc g++ make unzip subversion file dos2unix perl-modules python3 python

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

RUN apt-get update -y
RUN apt-get install \
    openjdk-8-jdk \
    ca-certificates-java \
    --assume-yes

RUN /usr/sbin/update-java-alternatives -s java-1.8.0-openjdk-amd64

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ANDROID_HOME="/opt"

ENV PATH "$PATH:$ANDROID_HOME/tools:$PATH"
ENV PATH "$PATH:$ANDROID_HOME/platform-tools:$PATH"

# RUN BUILD_TOOLS=($ANDROID_HOME/build-tools/*)
# RUN ANDROID_LATEST_BUILD_TOOLS="${BUILD_TOOLS[@]:(-1)}"
ENV PATH "$PATH:$ANDROID_HOME/build-tools/android-26:$PATH"

# RUN cpan File::Compare

ENV SDK_MANAGER_URL https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
RUN curl $SDK_MANAGER_URL -o /opt/sdktools.zip
RUN unzip /opt/sdktools.zip -d /opt

# ENV NDK_URL https://dl.google.com/android/repository/android-ndk-r14b-linux-x86_64.zip
# RUN curl $NDK_URL -o /opt/android-ndk-r14b.zip
# RUN unzip /opt/android-ndk-r14b.zip -d /opt

ENV NDK_URL http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
RUN curl $NDK_URL -o /opt/ndk.bin && \
    chmod +x /opt/ndk.bin && \
    cd /opt && ./ndk.bin && rm /opt/ndk.bin

ENV PATH "$PATH:$ANDROID_HOME/ndk-bundle:$PATH"
ENV ANDROID_NDK_ROOT /opt/android-ndk-r10e
# ENV ANDROID_NDK_ROOT="/opt/android-ndk-r14b"