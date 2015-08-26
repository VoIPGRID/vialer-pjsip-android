FROM android-ndk:10
COPY . /usr/src
WORKDIR /usr/src
CMD ["/bin/bash", "/usr/src/build.sh"]
