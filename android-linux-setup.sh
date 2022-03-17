#!/bin/bash

rm commandlinetools-*.zip

sudo apt-get install libc6-dev-i386 lib32z1 openjdk-8-jdk build-essential --yes

wget https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip
unzip commandlinetools-linux-8092744_latest.zip

export ANDROID_HOME=/usr/local/lib/android
export ANDROID_SDK_ROOT=$ANDROID_HOME/sdk

mkdir -p $ANDROID_SDK_ROOT

mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
cp -rf cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest
rm -rf cmdline-tools

cat << EOF >> $HOME/.bashrc

export ANDROID_HOME=/usr/local/lib/android
export ANDROID_SDK_ROOT=\$ANDROID_HOME/sdk
export PATH=\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
EOF

source $HOME/.bashrc

echo "ANDROID_HOME: $ANDROID_HOME"
echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
echo "PATH: $PATH"

yes | sdkmanager --licenses
yes | sdkmanager "platforms;android-21" "build-tools;21.1.2" "ndk-bundle"
