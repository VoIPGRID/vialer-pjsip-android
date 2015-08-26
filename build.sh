#!/bin/bash

# based on http://trac.pjsip.org/repos/wiki/Getting-Started/Android
if [ -z "$PJLIB_VERSION" ]
then
	PJLIB_VERSION=2.4.5
fi

if [ -z "$TARGETS" ]
then
    echo "No targets known" 1>&2
    TARGETS="x86 armeabi armeabi-v7a mips"
fi

SOURCE_URL="http://www.pjsip.org/release/$PJLIB_VERSION/pjproject-$PJLIB_VERSION.tar.bz2"
ARCHIVE_FILE="/usr/src/pjproject-$PJLIB_VERSION.tar.bz2"
SOURCE_DIR="/usr/src/pjproject-$PJLIB_VERSION"
OUTPUT_ARCHIVE="/tmp/pjsip.tar"
LOG_DIR=/usr/src
# Android-21 platform has significantly different libraries,
# so it isn't compatible with older versions. Use android-20 to go arround this
export APP_PLATFORM=android-19

function die {
    echo "$@" 1>&2
    exit 1
}
# Require a NDK installation
test -n "$ANDROID_NDK_ROOT" && test -d "$ANDROID_NDK_ROOT" || \
        die "Need a valid ANDROID_NDK_ROOT environment variable"

if [ ! -f $ARCHIVE_FILE ]
then
    curl -f $SOURCE_URL -o $ARCHIVE_FILE || die "Cannot download archive file"
fi




rm -f $OUTPUT_ARCHIVE
# Build all targets
for t in $TARGETS
do
    export TARGET_ABI="$t"

    # Make new source directory
    rm -rf $SOURCE_DIR
    tar xjf $ARCHIVE_FILE -C `dirname $SOURCE_DIR` || die "Cannot unpack archive"  
    # Copy our config_site.h to the source directory
    cp config_site.h $SOURCE_DIR/pjlib/include/pj/config_site.h


    pushd $SOURCE_DIR > /dev/null
    if [ -f config.status ]
    then
        make distclean > $LOG_DIR/make-distclean.txt
    fi

    # Build the library
    echo "Building for $TARGET_ABI" 1>&2
    # Configure this targetversion of android
    if [ $TARGET_ABI != "armeabi" ]
    then
        bash ./configure-android --use-ndk-cflags > $LOG_DIR/config-$TARGET_ABI.txt || die "Cannot configure $TARGET_ABI"
    else
        bash ./configure-android > $LOG_DIR-config-$TARGET_ABI.txt || die "Cannot configure $TARGET_ABI"
    fi
    # Make, but be silent about it
   (make dep && make) &> $LOG_DIR/pjlib-$TARGET_ABI.txt || \
            die "Cannot build library for $TARGET_ABI"

    # Build swig wrapper and .so file
    pushd ./pjsip-apps/src/swig > /dev/null
    make > $LOG_DIR/swig-$TARGET_ABI.txt || die "Cannot build Java Wrapper for $TARGET_ABI"
    # Move .so file to correct directory, build system always creates
    # the archive in the armeabi directory
    if [ "$TARGET_ABI" != "armeabi" ]
    then
        mv java/android/libs/armeabi java/android/libs/$TARGET_ABI
    fi
    popd > /dev/null # leave swig
    popd > /dev/null # leave source directory
    if [ ! -f $OUTPUT_ARCHIVE ]
    then
        # create new archive
        tar cvf $OUTPUT_ARCHIVE --exclude '*/pjsua2/app/' \
            -C $SOURCE_DIR/pjsip-apps/src/swig/java/android \
            src libs 1>&2 || die "Cannot create archive"
    else
        # add compiled libs
        tar rvf $OUTPUT_ARCHIVE \
            -C $SOURCE_DIR/pjsip-apps/src/swig/java/android \
            libs 1>&2 || die "Cannot add to archive"
    fi
done

cat $OUTPUT_ARCHIVE

