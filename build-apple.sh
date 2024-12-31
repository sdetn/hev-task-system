#!/bin/bash

set -e

XCFRAMEWORK_DIR="./apple_xcframework"

# buildStatic iphoneos -mios-version-min=15.0 arm64
buildStatic()
{
     echo "build for $1, $2, min version $3"

     if [ "$1" == "xros" ] || [ "$1" == "xrsimulator" ]; then
         local MIN_VERSION=""
     else
         local MIN_VERSION="-m$1-version-min=$3"
     fi
     make PP="xcrun --sdk $1 --toolchain $1 clang" \
          CC="xcrun --sdk $1 --toolchain $1 clang" \
          CFLAGS="-arch $2 $MIN_VERSION" \
          LFLAGS="-arch $2 $MIN_VERSION -Wl,-Bsymbolic-functions" static

     local OUTPUT_DIR="$XCFRAMEWORK_DIR/$1-$2"
     mkdir -p $OUTPUT_DIR
     local OUTPUT_ARCH_FILE="$OUTPUT_DIR/libhev-task-system.a"

     libtool -static -o $OUTPUT_ARCH_FILE bin/libhev-task-system.a
     make clean
}

mergeStatic()
{
     echo "merge for $1, $2, $3"
     local FIRST_LIB_FILE="$XCFRAMEWORK_DIR/$1-$2/libhev-task-system.a"
     local SECOND_LIB_FILE="$XCFRAMEWORK_DIR/$1-$3/libhev-task-system.a"
     local OUTPUT_DIR="$XCFRAMEWORK_DIR/$1-$2-$3"
     mkdir -p $OUTPUT_DIR
     local OUTPUT_ARCH_FILE="$OUTPUT_DIR/libhev-task-system.a"
     lipo -create \
          -arch $2 $FIRST_LIB_FILE \
          -arch $3 $SECOND_LIB_FILE \
          -output $OUTPUT_ARCH_FILE
}

rm -rf $XCFRAMEWORK_DIR
rm -rf HevTaskSystem.xcframework
mkdir $XCFRAMEWORK_DIR

# 查看支持的os版本和名字
# xcodebuild -showsdks
# xcrun --sdk iphoneos --toolchain xcode --show-sdk-platform-version
# xcrun --sdk iphonesimulator --toolchain xcode --show-sdk-platform-version
# xcrun --sdk macosx --toolchain xcode --show-sdk-platform-version
# xcrun --sdk appletvos --toolchain xcode --show-sdk-platform-version
# xcrun --sdk appletvsimulator --toolchain xcode --show-sdk-platform-version
# xcrun --sdk watchos --toolchain xcode --show-sdk-platform-version
# xcrun --sdk watchsimulator --toolchain xcode --show-sdk-platform-version
# xcrun --sdk xros --toolchain xcode --show-sdk-platform-version
# xcrun --sdk xrsimulator --toolchain xcode --show-sdk-platform-version

# 编译 iPhoneOS 平台
buildStatic iphoneos arm64 15.0
buildStatic iphonesimulator x86_64 15.0
buildStatic iphonesimulator arm64 15.0
mergeStatic iphonesimulator x86_64 arm64

# 编译 macOS 平台, keep same with flutter
buildStatic macosx x86_64 10.14
buildStatic macosx arm64 10.14
mergeStatic macosx x86_64 arm64

# 编译 Apple TV 平台
buildStatic appletvos arm64 17.0
buildStatic appletvsimulator x86_64 17.0
buildStatic appletvsimulator arm64 17.0
mergeStatic appletvsimulator x86_64 arm64

# 编译 Apple Watch 平台
buildStatic watchos arm64 7.0
buildStatic watchsimulator x86_64 7.0
buildStatic watchsimulator arm64 7.0
mergeStatic watchsimulator x86_64 arm64

# 编译 visionOS 平台
buildStatic xros arm64 1.0
buildStatic xrsimulator x86_64 1.0
buildStatic xrsimulator arm64 1.0
mergeStatic xrsimulator x86_64 arm64

INCLUDE_DIR="$XCFRAMEWORK_DIR/include"
mkdir -p $INCLUDE_DIR
cp ./include/*.h $INCLUDE_DIR
cp ./module.modulemap $INCLUDE_DIR
xcodebuild -create-xcframework \
    -library ./apple_xcframework/iphoneos-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/iphonesimulator-x86_64-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/macosx-x86_64-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/appletvos-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/appletvsimulator-x86_64-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/watchos-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/watchsimulator-x86_64-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/xros-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -library ./apple_xcframework/xrsimulator-x86_64-arm64/libhev-task-system.a -headers $INCLUDE_DIR \
    -output ./HevTaskSystem.xcframework

rm -rf ./apple_xcframework
