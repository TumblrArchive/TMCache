#!/usr/bin/env sh

xcodebuild -project tests/TMCache.xcodeproj -scheme TMCacheTests -sdk iphonesimulator TEST_AFTER_BUILD=YES clean build

