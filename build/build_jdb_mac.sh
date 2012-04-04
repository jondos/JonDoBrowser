#!/bin/bash

# Copyright (C) 2012 Jondos GmbH

# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, 
#    this list of conditions and the following disclaimer in the documentation 
#    and/or other materials provided with the distribution.
#  * Neither the name of the JonDos GmbH nor the names of its contributors may 
#    be used to endorse or promote products derived from this software without 
#    specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script fetches the latest sources of a Firefox release and verifies them.
# Afterwards the browser profiles are prepared and JonDoBrowser for Linux is
# built.

svnDir=https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build
langs="en de"
svn cat $svnDir/.mozconfig_mac > build/mozilla-release/.mozconfig

cd build/mozilla-release
make -f client.mk build
cd ../..
for lang in $langs; do
  appDir=JonDoBrowser-mac-$lang/Contents/MacOS
  cp -rf build/mozilla-release/mac_build/dist/Firefox.app/* $appDir/Firefox.app 
  mv JonDoBrowser-mac-$lang JonDoBrowser-mac-$lang.app
  zip -r9 JonDoBrowser-mac-$lang.zip JonDoBrowser-mac-$lang.app
done
#rm -rf build/mozilla-release
