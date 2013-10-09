#!/usr/bin/env sh

xcodebuild ONLY_ACTIVE_ARCH=NO -project tests/TMCache.xcodeproj -scheme TMCacheTests -sdk iphonesimulator TEST_AFTER_BUILD=YES clean build
