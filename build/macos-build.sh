BUILD_IOS=
BUILD_OSX=

unknownParameter()
{
    if [[ -n $2 &&  $2 != "" ]]; then
        echo Unknown argument \"$2\" for parameter $1.
    else
        echo Unknown argument $1
    fi
    die
}

parseArgs()
{
    while [ "$1" != "" ]; do
        case $1 in

        	-ios)
                BUILD_IOS=1
                ;;

            -osx)
                BUILD_OSX=1
                ;;

            --min-ios-version)
                if [ -n $2 ]; then
                    SDKVERSION=$2
                    shift
                else
                    missingParameter $1
                fi
                ;;
			--min-macosx-version)
				if [ -n $2 ]; then
					SDKVERSION=$2
					shift
				else
					missingParameter $1
				fi
				;;

            *)
                unknownParameter $1
                ;;
        esac

        shift
    done
}

parseArgs $@


if [[ -z $BUILD_IOS && -z $BUILD_OSX ]]; then
	BUILD_IOS=1
fi

CURRENT=`pwd`
# if [ -d "${CURRENT}/gmp/gmplib" ]; then
# 	exit
# fi

__pr="--print-path"
__name="xcode-select"
DEVELOPER=`${__name} ${__pr}`

GMP_VERSION="6.2.1"

if [[ -z $SDKVERSION ]]; then
    SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`
fi

OSX_PLATFORM=`xcrun --sdk macosx --show-sdk-platform-path`
OSX_SDK=`xcrun --sdk macosx --show-sdk-path`

IPHONEOS_PLATFORM=`xcrun --sdk iphoneos --show-sdk-platform-path`
IPHONEOS_SDK=`xcrun --sdk iphoneos --show-sdk-path`

IPHONESIMULATOR_PLATFORM=`xcrun --sdk iphonesimulator --show-sdk-platform-path`
IPHONESIMULATOR_SDK=`xcrun --sdk iphonesimulator --show-sdk-path`

CLANG=`xcrun --sdk iphoneos --find clang`
CLANGPP=`xcrun --sdk iphoneos --find clang++`

BITCODE_FLAGS=" -disable-llvm-optzns -O3"

downloadGMP()
{
    if [ ! -d "${CURRENT}/gmp" ]; then
        echo "Downloading GMP"
        curl -L -o "${CURRENT}/gmp-${GMP_VERSION}.tar.bz2" http://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
		tar xfj "gmp-${GMP_VERSION}.tar.bz2"
		mv gmp-${GMP_VERSION} gmp
		rm "gmp-${GMP_VERSION}.tar.bz2"
    fi
}

build()
{
	ARCH=$1
	SDK=$2
	PLATFORM=$3
	ARGS=$4
	TYPE=$5
 
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

downloadGMP

cd gmp
CURRENT=`pwd`

echo "GMP $CURRENT"

if [[ -n $BUILD_IOS ]]; then
#    build "armv7" "${IPHONEOS_SDK}" "${IPHONEOS_PLATFORM}" "" "ios"
	# build "armv7s" "${IPHONEOS_SDK}" "${IPHONEOS_PLATFORM}" "" "ios"
	build "arm64" "${IPHONEOS_SDK}" "${IPHONEOS_PLATFORM}" "" "ios"
#    build "i386" "${IPHONESIMULATOR_SDK}" "${IPHONESIMULATOR_PLATFORM}" "" "ios"
	build "x86_64" "${IPHONESIMULATOR_SDK}" "${IPHONESIMULATOR_PLATFORM}" "" "ios"

	[ -d gmplib/ios ] || mkdir -p gmplib/ios
	cp -r "${CURRENT}/gmplib-arm64-ios/include" gmplib/include

	echo "Creating Universal library"

    lipo \
        "${CURRENT}/gmplib-arm64-ios/lib/libgmp.a" \
        "${CURRENT}/gmplib-x86_64-ios/lib/libgmp.a" \
        -create -output "${CURRENT}/gmplib/ios/libgmp.a"

#        "${CURRENT}/gmplib-armv7-ios/lib/libgmp.a" 
#        "${CURRENT}/gmplib-i386-ios/lib/libgmp.a"

fi

if [[ -n $BUILD_OSX ]]; then
#    build "i386" "${OSX_SDK}" "${OSX_PLATFORM}" "ABI=32" "osx"
	build "x86_64" "${OSX_SDK}" "${OSX_PLATFORM}" "ABI=64" "osx"
	# maybe support arm64 later

	[ -d gmplib/osx ] || mkdir -p gmplib/osx
	cp -r "${CURRENT}/gmplib-x86_64-osx/include" gmplib/include

	echo "Creating Universal library"

    cp "${CURRENT}/gmplib-x86_64-osx/lib/libgmp.a" "${CURRENT}/gmplib/osx/libgmp.a"
	
	# modify this to support arm64 later
#    lipo \
#        "${CURRENT}/gmplib-i386-osx/lib/libgmp.a" \
#        "${CURRENT}/gmplib-x86_64-osx/lib/libgmp.a" \
#        -create -output "${CURRENT}/gmplib/osx/libgmp.a"
fi


echo "Done with GMP!"