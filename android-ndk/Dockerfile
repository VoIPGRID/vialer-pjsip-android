FROM debian
MAINTAINER "b.wiegmans@peperzaken.nl"
# Install necessary packages 
RUN apt-get update && \
    apt-get install -yq curl swig openjdk-7-jdk bzip2 gcc g++ make

# Download NDK and SDK from google
ENV SDK_URL http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz
ENV NDK_URL http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
RUN curl $SDK_URL -o /opt/sdk.tgz && \
    tar xzf /opt/sdk.tgz -C /opt 
RUN curl $NDK_URL -o /opt/ndk.bin && \
    chmod +x /opt/ndk.bin && \
    cd /opt && ./ndk.bin && rm /opt/ndk.bin

ENV ANDROID_SDK_ROOT /opt/android-sdk-linux
ENV ANDROID_NDK_ROOT /opt/android-ndk-r10e
ENV PATH $PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools
# Install SDKs yourself!
