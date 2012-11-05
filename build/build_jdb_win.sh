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
# Afterwards the browser profiles are prepared and JonDoBrowser for Windows is
# built.

svnBrowser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
mozKey=247CA658AA95F6171EB0F13EA7D75CC7C52175E2
releasePath=http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest
gpg="/c/Program Files (x86)/GNU/GnuPG/pub/gpg"
# These are the languages we support with JonDoBrowser
langs="en-US de"
# These languages need a special treatment (i.e. a non-default localized build
localeBuilds="de"

cleanup() {
  #Cleanup: Imitating make...
  echo "Cleaning up everything..."
  rm -rf tmp && rm -rf build
  exit 0
}

gpgVerification() {
  sigKey=$("${gpg}" --verify $1 2>&1 | tail -n1 | tr -d ' ' | \
           sed 's/.*[^A-F0-9]\([A-F0-9]\{40\}\)/\1/g')
  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    exit 1
  fi 
}

OPTSTR="ch"
getopts "${OPTSTR}" CMD_OPT
while [ $? -eq 0 ];
do
  case ${CMD_OPT} in
    c) cleanup;;
    h) echo '' 
       echo 'JonDoBrowser Build Script 1.0 (2012 Copyright (c) JonDos GmbH)'
       echo "usage: $0 [options]"
       echo ''
       echo 'Possible options are:'
       echo '-c removes old build cruft.'
       echo '-h prints this help text.'
       echo ''
       exit 0
       ;;
  esac
  getopts "${OPTSTR}" CMD_OPT
done

# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
# When we are using 'wget' in this script we retry three times if necessary
# as some mirrors of releases.mozilla.org seem to be not reachable at times...
echo "Getting the latest Firefox source version..."
ffVersion=$(wget -t 3 -qO - $releasePath/source | \
            grep -E 'firefox-[0-9]{2}\.[0-9](\.[0-9])*.source.tar.bz2' | \
            tail -n1 | \
            sed 's/.*\([0-9]\{2\}\.[0-9]\(\.[0-9]\)*\).*/\1/g')

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

#TODO: Mitigation of downgrade attacks
if [ "$ffVersion" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-$ffVersion.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources ..."
  wget -t 3 $releasePath/source/firefox-$ffVersion.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-$ffVersion.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget -t 3 $releasePath/source/firefox-$ffVersion.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-$ffVersion.source.tar.bz2.asc

cd ..

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

# Assuming we got the verified FF source copied to tmp first...
cd build && cp ../tmp/firefox-$ffVersion.source.tar.bz2 .
tar -xjvf firefox-$ffVersion.source.tar.bz2
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export $svnBrowser/build/patches 1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
for lang in $langs; do
  svn cat $svnBrowser/build/.mozconfig_win32 > .mozconfig
  echo "mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/win32_build_$lang" >> .mozconfig
  for localeBuild in $localeBuilds; do
    if [ "$lang" == "$localeBuild" ]; then
      # Now, we do all the stuff needed for localized builds
      cd ../../tmp
      # Checking out the locale repo
      hg clone -r FIREFOX_${ffVersion//./_}_RELEASE http://hg.mozilla.org/releases/l10n/mozilla-release/$lang 
      # We need the branding files in the locale repo as well
      rsync ../build/mozilla-release/browser/branding/jondobrowser/locales/en-US/brand* $lang/browser/branding/jondobrowser
      # Updating the .mozconfig
      cd ../build/mozilla-release
      echo "ac_add_options --enable-ui-locale=$lang" >> .mozconfig
      echo "ac_add_options --with-l10n-base=$(cd ../../tmp && pwd)" >> .mozconfig
      # Reconfiguring the build to be aware of the locale other than en-US
      python build/pymake/make.py -f client.mk configure
      break
    fi
  done

  python build/pymake/make.py -f client.mk build
  echo "Creating the final packages for locale $lang..."
  cd win32_build_$lang && python ../build/pymake/make.py package
  mv dist/firefox-$ffVersion.$lang.win32.zip ../../
  cd ..
done
cd ../../

# Now preparing the installer
echo "Now we gonna build the installer..."
svn export $svnBrowser/build/win profile
# We start with the en-US version and separate the locale specific parts one
# after the other...
unzip -d profile/Firefox/App build/firefox-$ffVersion.en-US.win32.zip
cd profile/Firefox/App/firefox
# We need the VC++ runtime files if we distribute JonDoBrowser. We are
# currently building with VC 2010, therefore the *100.dll's. And we are shipping
# them here as they are not included in the Express edition we currently use for
# compiling.
svn export $svnBrowser/build/msvcp100.dll
svn export $svnBrowser/build/msvcr100.dll

# Removing unneccessary files...
rm -rf searchplugins

#TODO: Moving the en-US locale specific files and adding all the other too.

# Getting the preference files...
cd ../../../full/profile
svn export $svnBrowser/build/langPatches/prefs_browser_de.js
svn export $svnBrowser/build/langPatches/prefs_browser_en.js

# Building the files...
cd ../../Firefox/Other/Source
# TODO: Why does that not work wiht the NSIS tool in mozilla-build?
# echo "Building the JonDoBrowser launcher..."
# makensisu-2.46.exe JonDoBrowserExe.nsi
echo "Building the JonDoBrowser installer..."
makensisu-2.46.exe JonDoBrowser.nsi
cd ../../../../
mv profile/JonDoBrowser*.exe .
rm -rf profile

exit 0
