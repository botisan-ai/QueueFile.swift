#!/bin/bash

set -ex

gh release upload $1 ./build/libqueuefile-rs.xcframework.zip --clobber