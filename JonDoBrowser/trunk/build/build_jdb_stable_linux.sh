#!/bin/bash

# Copyright (C) 2012-2013 Jondos GmbH

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

svnProfile="https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile"
svnBrowser="https://svn.jondos.de/svnpub/JonDoBrowser/trunk"
# The locales we support. en-US must be first as all the other localized builds
# are actually only a repackaging of the en-US one.
langs="en-US de"
# Allowing 32bit and 64bit JonDoBrowser builds
platform="linux-$(uname -m)"
jdbDir="JonDoBrowser"
jdbVersion="0.6"
# TODO: Shouldn't we check whether this one is still used/valid before actually
# building? Maybe that's something which is related to the more generic routine
# for the case the key was not imported yet which is mentioned below.
mozKey="247CA658AA95F6171EB0F13EA7D75CC7C52175E2"
releasePath="http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr"

prepareProfile() {
  echo "Fetching sources..."
  svn export $svnProfile
  for lang in $langs; do
    svn export $svnBrowser/build/langPatches/prefs_browser_$lang.js
  done
  svn export $svnBrowser/CHANGELOG
  svn export $svnBrowser/start-jondobrowser.sh
  chmod +x start-jondobrowser.sh
  svn export $svnBrowser/build/patches/xpi/jondofox.xpi

  echo "Preparing the profile..."
  # We do not need ProfileSwitcher in our JonDoBrowser, thus removing it.
  rm -rf profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\}.xpi
  # Patching the profile xpi to be optimized for JDB, sigh...
  unzip -d profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\} -o jondofox.xpi
  # TODO: Why does -f or -s not work? And removing the .xpi in the extensions folder if it exists...
  #if [ -f "profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi" ]
  #then
    rm profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi
  #fi
  # Cruft from the old JonDoFox-Profile...
  rm -f profile/prefs_portable*
  rm -f profile/bookmarks*
}

prepareLinuxProfiles() {
  echo "Creating language specific Linux profiles..."
  local profileDir

  for lang in $langs; do
    profileDir="$jdbDir-$lang/Data/profile"
    mkdir -p $jdbDir-$lang/App/Firefox
    mkdir -p $jdbDir-$lang/Data/plugins
    cp -rf profile $jdbDir-$lang/Data
    cp -f prefs_browser_$lang.js $profileDir/prefs.js
    cp start-jondobrowser.sh $jdbDir-$lang
    cp CHANGELOG $jdbDir-$lang
    mv -f $profileDir/places.sqlite_$lang $profileDir/places.sqlite
    rm -f $profileDir/places.sqlite_*
  done
}

cleanup() {
  #Cleanup: Imitating make...
  echo "Cleaning up everything..."
  rm -rf tmp && rm -rf build
  exit 0
}

OPTSTR="ch"
getopts "${OPTSTR}" CMD_OPT
while [ $? -eq 0 ];
do
  case ${CMD_OPT} in
    c) cleanup;;
    h) echo ''
       echo "JonDoBrowser Build Script 1.2 (2012-2013 Copyright (c) JonDos \
GmbH)"
       echo ''
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
echo "Getting the latest Firefox ESR source version..."
ffVersion=$(wget -t 3 -qO - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*esr.source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])*')

gpgVerification() {
  sigKey=$(gpg --verify $1 2>&1 | \
    grep -Eom 2 '([A-Z0-9]{4}\s*){10}' | tail -n1 | tr -d ' ')

  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    exit 1
  fi
}

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

#TODO: Mitigation of downgrade attacks
if [ "$ffVersion" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-${ffVersion}esr.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources ..."
  wget -t 3 $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-${ffVersion}esr.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget -t 3 $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine here assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-${ffVersion}esr.source.tar.bz2.asc

echo "Retrieving commonly used resources preparing the profiles..."
prepareProfile

# Now, we set up the JonDoBrowser profiles
echo "Setting up the JonDoBrowser profiles..."
prepareLinuxProfiles

cd ..

# Now, extracting, patching, rebranding and building JonDoBrowser...
if [ ! -d "build" ]; then
  mkdir build
fi

cd build && cp ../tmp/firefox-${ffVersion}esr.source.tar.bz2 .
tar -xjvf firefox-${ffVersion}esr.source.tar.bz2
# We do not want to care about specific ESR versions, thus we rename the dir
# to "mozilla-release".
mv mozilla-esr* mozilla-release
echo
echo "Downloading the build config file..."
svn cat $svnBrowser/build/.mozconfig_$platform > .mozconfig
echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export $svnBrowser/build/patches 1>/dev/null
fi

cp patches/*.patch mozilla-release/ && cd mozilla-release

if [ "$platform" == "linux-x86_64" ]; then
  svn export $svnBrowser/build/patches/os/PIE-64bit-Linux.patch
fi

svn export $svnBrowser/build/branding/jondobrowser browser/branding/jondobrowser

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building JonDoBrowser..."
for lang in $langs; do
  cp -f ../.mozconfig .
  if [ "$lang" == "en-US" ]; then
    make -f client.mk build
    echo "Creating the final packages..."
    cd linux_build && make package
  else
    # Now we do all the stuff needed for the non en-US localized builds
    cd ../../tmp
    # Checking out the locale repo
    # TODO: Can we make it even more sure that no one tampered with the repo(s)?
    # It seems as tags are not signed yet...
    hg clone -r FIREFOX_${ffVersion//./_}esr_RELEASE https://hg.mozilla.org/releases/l10n/mozilla-release/$lang
    cd $lang
    echo "Verifying the source repo..."
    hg verify
    retVal=$?
    if [ $retVal -eq 1 ]; then
      echo "Something went wrong with verifying the source repo! Exiting..."
      exit 1
    fi
    echo "Done."
    cd ..
    # We need the branding files in the locale repo as well
    rsync ../build/mozilla-release/browser/branding/jondobrowser/locales/en-US/brand* $lang/browser/branding/jondobrowser
    # Updating the .mozconfig
    cd ../build/mozilla-release
    echo "ac_add_options --with-l10n-base=$(cd ../../tmp && pwd)" >> .mozconfig
    echo "ac_add_options --disable-compile-environment" >> .mozconfig
    # Reconfiguring the build to be aware of the locale other than en-US
    make -f client.mk configure
    # Now we go and repack the binary
    cd linux_build/browser/locales
    # We are supposed to need the compare-locales tool for the merge-$lang
    # target. BUT it seems we can omit that which results in an error (127) but
    # adds the german language strings, though. Going this route for now as this
    # means less build dependencies...
    make merge-$lang LOCALE_MERGEDIR=mergedir
    make installers-$lang LOCALE_MERGEDIR=mergedir
    cd ../../
  fi

  echo "Creating the JonDoBrowser with $lang support..."
  cp dist/firefox-$ffVersion.$lang.$platform.tar.bz2 ../../../tmp
  cd ../../../tmp && tar -xjvf firefox-$ffVersion.$lang.$platform.tar.bz2

  jdbFinal=JonDoBrowser-$jdbVersion-$platform-$lang
  cp -rf firefox/* $jdbDir-$lang/App/Firefox
  mv $jdbDir-$lang $jdbDir
  tar -cf $jdbFinal.tar $jdbDir
  xz $jdbFinal.tar
  mv $jdbFinal.tar.xz ../
  rm -rf $jdbDir
  # TODO: Only needed if we need to build another localized build...
  cd ../build/mozilla-release
done

cd ../../../

exit 0
