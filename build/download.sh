#!/bin/bash

CURRENT=`pwd`

GMP_VERSION="6.2.1"

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

downloadGMP