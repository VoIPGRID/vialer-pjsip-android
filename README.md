# README

This repository allows you to build pjlib as a static library for android.
Architectures armeabi, armeabi-v7a, x86, and mips are currently supported.

## How To

Build the android-ndk docker image

    docker build -t android-ndk:10 android-ndk/

Then build the pjlib-android image

    docker build -t pjlib-android .

Finally run the program:

    docker run --rm pjlib-android > pjsip.tar

And test the archive:

    tar tvf pjsip.tar
