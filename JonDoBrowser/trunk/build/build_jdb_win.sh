#!/bin/bash

cd jdbBuild/mozilla-release
python build/pymake/make.py -f client.mk
cd win32_build
python ../build/pymake/make.py package
cd dist
mv firefox*.zip ../../../
cd ../../
rm -rf win32_build
cd ..
