#!/bin/bash

__pr="--print-path"
__name="xcode-select"
DEVELOPER=`${__name} ${__pr}`

OSX_PLATFORM=`xcrun --sdk macosx --show-sdk-platform-path`
OSX_SDK=`xcrun --sdk macosx --show-sdk-path`

IPHONEOS_PLATFORM=`xcrun --sdk iphoneos --show-sdk-platform-path`
IPHONEOS_SDK=`xcrun --sdk iphoneos --show-sdk-path`

IPHONESIMULATOR_PLATFORM=`xcrun --sdk iphonesimulator --show-sdk-platform-path`
IPHONESIMULATOR_SDK=`xcrun --sdk iphonesimulator --show-sdk-path`

CLANG=`xcrun --sdk iphoneos --find clang`
CLANGPP=`xcrun --sdk iphoneos --find clang++`

BITCODE_FLAGS=" -disable-llvm-optzns -O3"

mkdir -p gmp
cd gmp
CURRENT=`pwd`

build()
{
    case $1 in
        arm64-ios)
            ARCH=arm64
            SDK=${IPHONEOS_SDK}
            PLATFORM=${IPHONEOS_PLATFORM}
            ARGS=""
            TYPE=ios
            ;;
        x86_64-ios)
            ARCH=x86_64
            SDK=${IPHONESIMULATOR_SDK}
            PLATFORM=${IPHONESIMULATOR_PLATFORM}
            ARGS=""
            TYPE=ios
            ;;
        *)
            ARCH=x86_64
            SDK=${OSX_SDK}
            PLATFORM=${OSX_PLATFORM}
            ARGS="ABI=64"
            TYPE=osx
            ;;
    esac
 
	make clean &> "${CURRENT}/clean.log"
	make distclean &> "${CURRENT}/clean.log"

	export PATH="${PLATFORM}/Developer/usr/bin:${DEVELOPER}/usr/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

	if [ -d "gmplib-${ARCH}-${TYPE}" ] ; then
		rm -rf "gmplib-${ARCH}-${TYPE}"
	fi
	
	mkdir "gmplib-${ARCH}-${TYPE}"

	EXTRAS="-arch ${ARCH}"
	if [ "${TYPE}" == "ios" ]; then
		EXTRAS="$EXTRAS -miphoneos-version-min=${SDKVERSION} -no-integrated-as -target ${ARCH}-apple-darwin"
	fi

	if [ "${TYPE}" == "osx" ]; then
        echo "macOS deployment target ${SDKVERSION}"
		EXTRAS="$EXTRAS -mmacosx-version-min=${SDKVERSION} "
	fi

	if [ "${ARCH}" == "i386" ]; then
		EXTRAS="${EXTRAS} -m32"
	fi

	CFLAGS=" ${BITCODE_FLAGS} -isysroot ${SDK} -Wno-error -Wno-implicit-function-declaration ${EXTRAS} -fvisibility=hidden"

	echo "Configuring for ${ARCH} ${TYPE}..."
	./configure --prefix="${CURRENT}/gmplib-${ARCH}-${TYPE}" CC="${CLANG} ${CFLAGS}" LDFLAGS="${CFLAGS}" CPP="${CLANG} -E"  CPPFLAGS="${CFLAGS}" \
	--host=x86_64-apple-darwin --disable-assembly --enable-static --disable-shared ${ARGS} &> "${CURRENT}/gmplib-${ARCH}-${TYPE}-configure.log"

	echo "Make in progress for ${ARCH} ${TYPE}..."
	make -j`sysctl -n hw.logicalcpu_max` &> "${CURRENT}/gmplib-${ARCH}-${TYPE}-build.log"
	# if [ "${ARCH}" == "i386" ]; then
		# echo "check in progress for ${ARCH}"
		# make check &> "${CURRENT}/gmplib-${ARCH}-check.log"
	# fi
	echo "Install in progress for ${ARCH} ${TYPE}..."
	make install &> "${CURRENT}/gmplib-${ARCH}-${TYPE}-install.log"
}

build $1