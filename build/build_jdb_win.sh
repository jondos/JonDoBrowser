#!/bin/bash

cd jdbBuild/mozilla-release
python -OO build/pymake/make.py -f client.mk
cd win32_build
python -OO ../build/pymake/make.py package
cd dist
mv firefox*.zip ../../../
cd ../../
rm -rf win32-build
cd ..
