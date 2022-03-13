#!/bin/bash

sudo apt install libgmp-dev m4 build-essential --yes

mkdir -p gmp
cd gmp
CURRENT=`pwd`

echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
export NDK=$ANDROID_SDK_ROOT/ndk-bundle
echo "NDK: $NDK"

# Only choose one of these, depending on your build machine...
# export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

# Only choose one of these, depending on your device...
# export TARGET=aarch64-linux-android
# export TARGET=armv7a-linux-androideabi
# export TARGET=i686-linux-android
# export TARGET=x86_64-linux-android

# Set this to your minSdkVersion.
export API=21

# Configure and build.
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

./configure --prefix=$HOME/usr/local/$TARGET --host=$TARGET
make
make install
make clean
make distclean