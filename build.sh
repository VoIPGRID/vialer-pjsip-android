#!/bin/bash

SSL_ARCHS=(
    "android"           # armabi
    "android-armeabi"   # armeabi-v7a
    "android64-aarch64" # arm64-v8a"
    "android-x86"       # x86
    "android64"         # x86_64
    "android-mips64"    # mips64

    # "android-mips"      # mips
)

AVAILABLE_ARCHS=(
    "armeabi"
    "armeabi-v7a"
    "arm64-v8a"
    "x86"
    "x86_64"
    "mips64"

    # "mips"
)

export APP_PLATFORM="android-19"
export ANDROID_API=19
export GCC_VERSION="4.9"
export AVAILABLE_ARCHS
export USE_ARCHS=()
export USE_SSL_ARCHS=()

export BASE_DIR=`pwd -P`

export PJSIP_VERSION="latest"
export PJSIP_BASE_URL="http://svn.pjsip.org/repos/pjproject"
export PJSIP_DIR="$BASE_DIR/pjsip"
export PJSIP_FINAL_LIB_DIR="$BASE_DIR/lib"
export PJSIP_FINAL_JAVA_DIR="$BASE_DIR/java"
export PJSIP_SRC_DIR="$BASE_DIR/pjsip/src"
export PJSIP_LOGS_DIR="$BASE_DIR/pjsip/logs"
export PJSIP_TMP_DIR="$BASE_DIR/pjsip/temp"
export PJSIP_CONFIG_SITE_H="$PJSIP_DIR/config_site.h"
export PJSIP_SWIG_DIR="$PJSIP_SRC_DIR/pjsip-apps/src/swig"
export PJSUA_GENERATED_SRC_PATH="$PJSIP_SWIG_DIR/java/android/app/src"
export PJSUA_GENERATED_SO_PATH="$PJSIP_SWIG_DIR/java/android/app/src/main/jniLibs/armeabi/libpjsua2.so"

export BUILD_DIR="$PJSIP_DIR/external"
export SSL_LOGS_DIR="$BASE_DIR/pjsip/logs"
export SSL_BUILD_DIR="$BUILD_DIR/ssl"
export SSL_SRC_DIR="$SSL_BUILD_DIR/src"
export SSL_OUTPUT_DIR="$BUILD_DIR/lib/ssl"

export OPUS_BUILD_DIR="$BUILD_DIR/opus"
export OPUS_SRC_DIR="$OPUS_BUILD_DIR/src"
export OPUS_OUTPUT_DIR="$BUILD_DIR/lib/opus"

export SWIG_DIR="$BUILD_DIR/swig"
export ACTIVE_NDK_VERSION="r10e"
export ANDROID_NDK_HOME="/opt/android-ndk-${ACTIVE_NDK_VERSION}/"
export ANDROID_NDK_TOOLCHAIN_PATH="${ANDROID_NDK_HOME}ndk-toolchains"


function build_ssl() {
    echo "Removing SSL directory"
    rm -rf $SSL_BUILD_DIR
    mkdir -p $SSL_BUILD_DIR
    mkdir -p $SSL_SRC_DIR

    rm -rf $ANDROID_NDK_TOOLCHAIN_PATH
    mkdir -p $ANDROID_NDK_TOOLCHAIN_PATH


    echo "Removing SSL output directory"
    rm -rf $SSL_OUTPUT_DIR
    mkdir -p $SSL_OUTPUT_DIR

    pushd . > /dev/null
    cd $SSL_SRC_DIR

    # ssl_version="openssl-1.0.2o";
    ssl_version="openssl-1.1.0f";

    ssl_url="https://www.openssl.org/source/$ssl_version.tar.gz"
    # ssl_url="https://github.com/openssl/openssl/archive/$ssl_version.tar.gz"
    echo "Downloading $ssl_version"
    curl -LO $ssl_url
    echo "Extracting $ssl_version to $SSL_SRC_DIR"
    tar zxf "$ssl_version.tar.gz" --strip 1
    rm "$ssl_version.tar.gz"

    mkdir -p $SSL_LOGS_DIR

    for ((i=0; i < ${#AVAILABLE_ARCHS[@]}; i++))
    do
        ssl_arch="${SSL_ARCHS[i]}"
        android_arch="${AVAILABLE_ARCHS[i]}"

        start=`date +%s`
        echo "Start time of ssl $android_arch: $start"
        echo $android_arch
        echo $ssl_arch

        mkdir -p $SSL_OUTPUT_DIR/$android_arch

        clean_vars

        configure_base_ssl_export $ssl_arch $android_arch

        if [[ $ssl_version != openssl-1.1.* ]]; then
            if [[ $ssl_arch == "android-armeabi" ]]; then
                ARCH="android-armv7"
            elif [[ $ssl_arch == "android64" ]]; then
                ARCH="linux-x86_64 shared no-ssl2 no-ssl3 no-hw "
            elif [[ "$ssl_arch" == "android64-aarch64" ]]; then
                ARCH="android shared no-ssl2 no-ssl3 no-hw "
            fi
        fi

        arch_log="$SSL_LOGS_DIR/$android_arch-ssl-make.log"

        ./Configure $ARCH \
                    --prefix=${SSL_OUTPUT_DIR}/${android_arch} \
                    --with-zlib-include=$SYSROOT/usr/include \
                    --with-zlib-lib=$SYSROOT/usr/lib \
                    --openssldir="$SSL_OUTPUT_DIR/$android_arch" \
                    zlib \
                    no-asm \
                    no-shared \
                    no-unit-test \
                    no-comp \
                    no-dso
        PATH=$TOOLCHAIN_PATH:$PATH

        make clean

        make depend
        # if make -j4; then
        make
            # make install >> $arch_log 2>&1
        make install_sw
        make install_ssldirs
        # fi

        end=`date +%s`
        echo "End time of ssl $arch: $end"
        runtime=$((end-start))
        echo "Total ssl compile time of $arch: $runtime"
        # fi
    done

}

function configure_base_ssl_export() {
    ARCH=$1; OUT=$2; CLANG=${3:-""};

    TOOLS_ROOT="$ANDROID_NDK_HOME/toolchains/"

    TOOLCHAIN_ROOT=${TOOLS_ROOT}/${OUT}-android-toolchain

    echo $TOOLCHAIN_ROOT
    if [ "$ARCH" == "android" ]; then
        export ARCH_FLAGS="-mthumb"
        export ARCH_LINK=""
        export TOOL="arm-linux-androideabi"
        NDK_FLAGS="--arch=arm"
        PLATFORM="android-19"
    elif [ "$ARCH" == "android-armeabi" ]; then
        export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -mfpu=neon"
        export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
        export TOOL="arm-linux-androideabi"
        NDK_FLAGS="--arch=arm"
        PLATFORM="android-19"
    elif [ "$ARCH" == "android64-aarch64" ]; then
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        export TOOL="aarch64-linux-android"
        NDK_FLAGS="--arch=arm64"
        PLATFORM="android-21"
    elif [ "$ARCH" == "android-x86" ]; then
        export ARCH_FLAGS="-march=i686 -mtune=intel -msse3 -mfpmath=sse -m32"
        export ARCH_LINK=""
        export TOOL="i686-linux-android"
        NDK_FLAGS="--arch=x86"
        PLATFORM="android-19"
    elif [ "$ARCH" == "android64" ]; then
        export ARCH_FLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
        export ARCH_LINK=""
        export TOOL="x86_64-linux-android"
        NDK_FLAGS="--arch=x86_64"
        PLATFORM="android-21"
    elif [ "$ARCH" == "android-mips" ]; then
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        export TOOL="mipsel-linux-android"
        NDK_FLAGS="--arch=mips"
        PLATFORM="android-19"
    elif [ "$ARCH" == "android-mips64" ]; then
        export ARCH="linux64-mips64"
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        export TOOL="mips64el-linux-android"
        NDK_FLAGS="--arch=mips64"
        PLATFORM="android-21"
    fi;

    # python $ANDROID_NDK_ROOT/build/tools/make_standalone_toolchain.py \
            # --api ${ANDROID_API} \
    bash $ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh \
        --platform=${PLATFORM} \
        --stl=libc++ \
        --install-dir=${TOOLCHAIN_ROOT} \
        $NDK_FLAGS

    export TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/bin
    export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
    export SYSROOT=${TOOLCHAIN_ROOT}/sysroot
    export CROSS_SYSROOT=$SYSROOT
    if [ -z "${CLANG}" ]; then
        export CC=${NDK_TOOLCHAIN_BASENAME}-gcc
        export CXX=${NDK_TOOLCHAIN_BASENAME}-g++
    else
        export CC=${NDK_TOOLCHAIN_BASENAME}-clang
        export CXX=${NDK_TOOLCHAIN_BASENAME}-clang++
    fi;
    export LINK=${CXX}
    export LD=${NDK_TOOLCHAIN_BASENAME}-ld
    export AR=${NDK_TOOLCHAIN_BASENAME}-ar
    export RANLIB=${NDK_TOOLCHAIN_BASENAME}-ranlib
    export STRIP=${NDK_TOOLCHAIN_BASENAME}-strip
    export CPPFLAGS=${CPPFLAGS:-""}
    export LIBS=${LIBS:-""}
    export CFLAGS="${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64"
    export CXXFLAGS="${CFLAGS} -std=c++11 -frtti -fexceptions"
    export LDFLAGS="${ARCH_LINK}"
    echo "**********************************************"
    echo "use ANDROID_API=${ANDROID_API}"
    echo "use NDK=${ANDROID_NDK_ROOT}"
    echo "export ARCH=${ARCH}"
    echo "export NDK_TOOLCHAIN_BASENAME=${NDK_TOOLCHAIN_BASENAME}"
    echo "export SYSROOT=${SYSROOT}"
    echo "export CC=${CC}"
    echo "export CXX=${CXX}"
    echo "export LINK=${LINK}"
    echo "export LD=${LD}"
    echo "export AR=${AR}"
    echo "export RANLIB=${RANLIB}"
    echo "export STRIP=${STRIP}"
    echo "export CPPFLAGS=${CPPFLAGS}"
    echo "export CFLAGS=${CFLAGS}"
    echo "export CXXFLAGS=${CXXFLAGS}"
    echo "export LDFLAGS=${LDFLAGS}"
    echo "export LIBS=${LIBS}"
    echo "**********************************************"
}

function build_opus() {
    rm -rf $OPUS_BUILD_DIR
    rm -rf $OPUS_OUTPUT_DIR
    rm -rf $OPUS_SRC_DIR

    mkdir -p $OPUS_BUILD_DIR
    mkdir -p $OPUS_OUTPUT_DIR
    mkdir -p $OPUS_SRC_DIR

    cd $OPUS_SRC_DIR

    opus_version="1.2.1"
    opus_url="https://ftp.osuosl.org/pub/xiph/releases/opus/opus-$opus_version.tar.gz"

    curl -LO $opus_url
    echo "Using opus-${opus_version}.tar.gz"

    tar zxf "opus-${opus_version}.tar.gz" --strip 1

    mkdir -p "$OPUS_SRC_DIR/jni"

    cd $OPUS_SRC_DIR

    cp "$BASE_DIR/opus-android.mk" "jni/Android.mk"
    cp "$BASE_DIR/opus-Application.mk" "jni/Application.mk"

    cd $OPUS_SRC_DIR

    NDK_TOOLCHAIN_VERSION=4.9 $ANDROID_NDK_ROOT/ndk-build NDK_APPLICATION_MK=jni/Application.mk APP_BUILD_SCRIPT=jni/Android.mk NDK_PROJECT_PATH=build NDK_DEBUG=1

    for arch in "${USE_ARCHS[@]}"; do
        mkdir -p "${OPUS_OUTPUT_DIR}/${arch}/include/opus"
        mkdir -p "${OPUS_OUTPUT_DIR}/${arch}/lib"

        cp -r "${OPUS_SRC_DIR}/include/." "${OPUS_OUTPUT_DIR}/${arch}/include/opus"
        cp -r "${OPUS_SRC_DIR}/build/obj/local/${arch}/libopus.a" "${OPUS_OUTPUT_DIR}/${arch}/lib/libopus.a"
    done
}

function clean_vars () {
    unset TOOLCHAIN_PATH
    unset MACHINE
    unset RELEASE
    unset SYSTEM
    unset ARCH
    unset CROSS_COMPILE
    unset HOSTCC
    unset TOOL
    unset NDK_TOOLCHAIN_BASENAME
    unset CC
    unset CXX
    unset LINK
    unset LD
    unset AR
    unset RANLIB
    unset STRIP
    unset ARCH_FLAGS
    unset ARCH_LINK
    unset CPPFLAGS
    unset CXXFLAGS
    unset CFLAGS
    unset LDFLAGS
    unset LIBS
    unset TARGET_ABI
    unset STDCPP_CFLAGS
    unset STDCPP_TC_VER
    unset TDCPP_LIBS
    unset STDCPP_LDFLAGS
    unset _LDFLAGS
}

function _______build_ssl2() {
    rm -rf $SSL_BUILD_DIR
    mkdir -p $SSL_BUILD_DIR

    rm -rf $ANDROID_NDK_TOOLCHAIN_PATH
    mkdir -p $ANDROID_NDK_TOOLCHAIN_PATH

    pushd . > /dev/null
    cd $SSL_BUILD_DIR

    ssl_url="https://github.com/openssl/openssl/archive/OpenSSL_1_1_0f.tar.gz"
    echo "Downloading OpenSSL 1.1.0f"
    curl -LO $ssl_url
    echo "Extracting OpenSSL 1.1.0f to $SSL_BUILD_DIR"
    tar zxf "OpenSSL_1_1_0f.tar.gz" --strip 1
    rm "OpenSSL_1_1_0f.tar.gz"

    openssl_sh_url="https://wiki.openssl.org/images/7/70/Setenv-android.sh"
    echo "Downloading OpenSSL Setenv-android.sh"
    curl -LO $openssl_sh_url

    sed -i -e 's/_ANDROID_EABI="arm-linux-androideabi-4.8"/_ANDROID_EABI="arm-linux-androideabi-4.9"/g' "$SSL_BUILD_DIR/Setenv-android.sh"
    sed -i -e 's/_ANDROID_API="android-18"/_ANDROID_API="android-21"/g' "$SSL_BUILD_DIR/Setenv-android.sh"
    sed -i -e 's/_ANDROID_NDK="android-ndk-r9"/_ANDROID_NDK="android-ndk-r10e"/g' "$SSL_BUILD_DIR/Setenv-android.sh"

    chmod a+x Setenv-android.sh
    dos2unix Setenv-android.sh
    set_ssl_env=". ./Setenv-android.sh"
    $set_ssl_env

    ./config shared no-ssl3 no-comp no-hw no-engine --openssldir=$SSL_BUILD_DIR

    make depend
    make all

    echo $ANDROID_NDK_TOOLCHAIN

    make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib
}

function download_pjsip () {
    if [ $PJSIP_VERSION = "latest" ]; then
        latest_pjsip_tag=$(svn ls "$PJSIP_BASE_URL/tags/" | tail -n 1  | cut -d "/" -f 1 | sort -t . -k 1,2n -k 2,2n -k 3,2)
        PJSIP_VERSION=$latest_pjsip_tag
    fi

    checkout_url="${PJSIP_BASE_URL}/tags/${PJSIP_VERSION}"
    # checkout_url="${PJSIP_BASE_URL}/trunk"

    echo "Download PJSIP version: ${PJSIP_VERSION}"
    echo "Checkout url: $checkout_url"
    mkdir -p $PJSIP_DIR
    svn export $checkout_url $PJSIP_SRC_DIR -q
    echo "Done downloading PJSIP source"
    echo "============================="
}

function clean_pjsip_src () {
    echo "Removing: $PJSIP_SRC_DIR"
    rm -rf $PJSIP_SRC_DIR
}

function full_clean_pjsip () {
    echo "WARNING: About to full clean the build directories."
    echo "Waiting 5 seconds for sanity check... CTRL-C to abort now"
    sleep 1 && echo "4..." && \
    sleep 1 && echo "3..." && \
    sleep 1 && echo "2..." && \
    sleep 1 && echo "1..." && \
    sleep 1

    echo "Removing: $PJSIP_SRC_DIR"
    rm -rf $PJSIP_SRC_DIR
    echo "Removing: $PJSIP_FINAL_LIB_DIR"
    rm -rf $PJSIP_FINAL_LIB_DIR
    echo "Removing: $PJSIP_FINAL_JAVA_DIR"
    rm -rf $PJSIP_FINAL_JAVA_DIR
    echo "Removing: $PJSIP_LOGS_DIR"
    rm -rf $PJSIP_LOGS_DIR
    echo "Removing: $BUILD_DIR"
    rm -rf $BUILD_DIR
    echo "Removing: $BASE_DIR/tmp"
    rm -rf $BASE_DIR"/tmp"
    echo "Done cleaning PJSIP source"
    echo "============================="
}

function install_android_sdks() {
    mkdir -p /root/.android
    touch /root/.android/repositories.cfg

    echo "Install latest SDK:"
    /opt/tools/bin/sdkmanager "platforms;android-26"
    /opt/tools/bin/sdkmanager "platforms;android-25"
    /opt/tools/bin/sdkmanager "platform-tools"
    echo "Install latest build-tools:"
    /opt/tools/bin/sdkmanager "build-tools;26.0.0"
    /opt/tools/bin/sdkmanager "build-tools;25.0.2"
    echo "Install latest tools:"
    /opt/tools/bin/sdkmanager "tools"

    (while sleep 3; do echo "y"; done) | /opt/tools/bin/sdkmanager --licenses

    # ln -s /opt/platforms/android-26/ ln -s ${ANDROID_NDK_HOME}platforms/android-26/

    # echo "Install latest NDK:"
    # yes | /opt/tools/bin/sdkmanager "ndk-bundle"

    # export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk-bundle"
}

function config_site () {
    echo "Creating config_site.h"

    if [ -f $PJSIP_CONFIG_SITE_H ]; then
        rm -rf $PJSIP_CONFIG_SITE_H
    fi

    echo "#define PJ_CONFIG_ANDROID 1" >> $PJSIP_CONFIG_SITE_H
    echo "#include <pj/config_site_sample.h>" >> $PJSIP_CONFIG_SITE_H

    echo "#define PJMEDIA_SDP_NEG_ANSWER_SYMMETRIC_PT 0" >> $PJSIP_CONFIG_SITE_H
    echo "#define PJMEDIA_HAS_OPUS_CODEC 1" >> $PJSIP_CONFIG_SITE_H
    echo "#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1" >> $PJSIP_CONFIG_SITE_H

    while IFS=',' read -ra CONFIG_SITE_OPTION; do
        for i in "${CONFIG_SITE_OPTION[@]}"; do
            echo "#define $i" >> $PJSIP_CONFIG_SITE_H
        done
    done <<< $CONFIG_SITE_OPTIONS

    echo "Done creating new config_site.h"
    echo "============================="
}

function build_archs() {
    echo "Building ABIs"

    for arch in "${USE_ARCHS[@]}"; do
        mkdir -p "$PJSIP_FINAL_LIB_DIR/$arch"
        tmp=$arch

        clean_vars
        configure_$tmp

        clean_vars
        _build $tmp

        clean_vars
        _swig $tmp

        echo "Copying PJSUA.so for $tmp"
        ls $PJSIP_FINAL_LIB_DIR/$tmp
        mv "$PJSUA_GENERATED_SO_PATH" "$PJSIP_FINAL_LIB_DIR/$tmp"

        echo "Copying PJSUA java bindings to final build directory..."
        cp -r $PJSUA_GENERATED_SRC_PATH $PJSIP_FINAL_JAVA_DIR

        clean_pjsip_src
        download_pjsip
    done



    echo "Done building the ABIs"
    echo "============================="
}

function configure_armeabi() {
    echo "Configure for armeabi"
    export EXTRA_FLAGS=""
}

function configure_armeabi-v7a() {
    echo "Configure for armeabi-v7a"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function configure_x86() {
    echo "Configure for x86"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function configure_x86_64() {
    echo "Configure for x86_64"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function configure_arm64-v8a() {
    echo "Configure for arm64-v8a"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function configure_mips() {
    echo "Configure for mips"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function configure_mips64() {
    echo "Configure for mips64"
    export EXTRA_FLAGS="--use-ndk-cflags"
}

function _build() {
    arch=$1

    echo "Building $arch"
    pushd . > /dev/null
    cd $PJSIP_SRC_DIR

    mkdir -p $PJSIP_LOGS_DIR
    echo $PJSIP_LOGS_DIR
    arch_log="$PJSIP_LOGS_DIR/$arch.log"
    echo $arch

    cp $PJSIP_CONFIG_SITE_H "$BASE_DIR/pjsip/src/pjlib/include/pj"
    configure="./configure-android $EXTRA_FLAGS --with-opus=$OPUS_OUTPUT_DIR/$arch --with-ssl=$SSL_OUTPUT_DIR/$arch"
    # configure="./configure-android $EXTRA_FLAGS"

    echo $configure
    echo $arch
    NDK_TOOLCHAIN_VERSION=4.9 TARGET_ABI=$arch APP_PLATFORM=$APP_PLATFORM $configure

    make dep
    make clean
    make

    echo "Done building for $arch"
    echo "============================="

    popd > /dev/null
}

function _swig() {
    echo "BUILDING SWIG!"

    pushd . > /dev/null

    cd $PJSIP_SWIG_DIR
    arch_log="$PJSIP_LOGS_DIR/swig-$1.log"
    make clean
    make

    echo "DONE BUILDING SWIG"

    popd > /dev/null
}

function build_aar() {
    echo "BUILD AAR!"
    pushd . > /dev/null

    rm -rf $BASE_DIR"/tmp"
    mkdir -p $BASE_DIR"/tmp"
    cd $BASE_DIR"/tmp"

    tar zxf "../android-library-template.tar.gz"

    mkdir -p $PJSIP_FINAL_JAVA_DIR"/src/main/java/org/pjsip"

    echo $PJSIP_FINAL_JAVA_DIR"/main/java/org/pjsip"
    ls  $PJSIP_FINAL_JAVA_DIR"/main/java/org/pjsip"
    cp -r $PJSIP_FINAL_JAVA_DIR"/main/java/." "android-library-template/app/src/main/java/"

    rm -rf "android-library-template/app/src/main/java/org/pjsip/pjsua2/app"

    ls -ls $PJSIP_FINAL_LIB_DIR"/."
    cp -rf $PJSIP_FINAL_LIB_DIR"/." $BASE_DIR"/tmp/android-library-template/app/libs"

    mkdir -p $BASE_DIR"/tmp/android-library-template/app/src/main/jniLibs"
    cp -rf $PJSIP_FINAL_LIB_DIR"/." $BASE_DIR"/tmp/android-library-template/app/src/main/jniLibs"

    cd "$BASE_DIR/tmp/android-library-template"

    # sed -i -e 's/ndk.dir=\/Users\/redmerloen\/Library\/Android\/sdk\/ndk-bundle/ndk.dir=\/opt\/android-ndk-r14b/g' $BASE_DIR"/tmp/android-library-template/local.properties"
    sed -i -e 's/ndk.dir=\/Users\/redmerloen\/Library\/Android\/sdk\/ndk-bundle/ndk.dir=\/opt\/android-ndk-r10e/g' $BASE_DIR"/tmp/android-library-template/local.properties"
    sed -i -e 's/sdk.dir=\/Users\/redmerloen\/Library\/Android\/sdk/sdk.dir=\/opt/g' $BASE_DIR"/tmp/android-library-template/local.properties"

    ./gradlew assembleRelease

    cp $BASE_DIR/tmp/android-library-template/app/build/outputs/aar/app-release.aar $BASE_DIR/pjsip.aar
}

if [ -z ${USE_ARCHS} ]; then
    for arch in "${AVAILABLE_ARCHS[@]}"; do
        USE_ARCHS+=($arch)
    done
fi

start=`date +%s`
clean_pjsip_src
download_pjsip
full_clean_pjsip
download_pjsip
install_android_sdks
build_opus
build_ssl
config_site
build_archs
build_aar
end=`date +%s`
echo "End time: $end"
runtime=$((end-start))
echo "Total script runtime: $runtime"