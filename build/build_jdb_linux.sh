#!/bin/bash

# This script fetches the latest sources of a Firefox release and verifies them.
# Afterwards the browser profiles are prepared and JonDoBrowser for Linux is
# built.

svn_profile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svn_browser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
langs="en de"
# We only need the german language pack currently as english is the default
xpiLang=de
platforms="linux-i686 mac"
mozKey=247CA658AA95F6171EB0F13EA7D75CC7C52175E2 
releasePath=http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/
# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
# When we are using 'wget' in this script we retry three times if necessary
# as some mirrors of releases.mozilla.org seem to be not reachable at times...
version=$(wget -t 3 -qO - ${releasePath}source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9]).source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])')

gpgVerification() {
  file=$1
  sigKey=$(gpg --verify $1 2>&1 | \
    grep -Eom 2 '([A-Z0-9]{4}\s*){10}' | tail -n1 | tr -d ' ')

  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    exit 1
  fi 
}

prepareLinuxProfiles() {
  echo "Creating language specific Linux profiles..."
  local profileDir
  local jdbPlatform="JonDoBrowser-linux"

  for lang in $langs; do
    # TODO: Maybe we should include the JDB version in the directory name.
    # Something like JonDoBrowser-linux-x.x.x-lang
    profileDir=${jdbPlatform}-$lang/Data/profile
    mkdir -p ${jdbPlatform}-$lang/App/Firefox
    mkdir -p ${jdbPlatform}-$lang/Data/plugins
    # We do not need ProfileSwitcher in our JonDoBrowser, thus removing it.
    rm -rf profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\} 
    cp -rf profile ${jdbPlatform}-$lang/Data
    svn cat $svn_browser/build/langPatches/prefs_browser_$lang.js > \
      ${profileDir}/prefs.js
    svn cat $svn_browser/start-jondobrowser.sh > \
      ${jdbPlatform}-$lang/start-jondobrowser.sh
    chmod +x ${jdbPlatform}-$lang/start-jondobrowser.sh
    mv -f ${profileDir}/places.sqlite_$lang ${profileDir}/places.sqlite
    # Cruft from the old JonDoFox-Profile...
    rm -f ${profileDir}/prefs_portable*
    rm -f ${profileDir}/places.sqlite_*
    rm -f ${profileDir}/bookmarks*
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    if [ "$lang" = "de" ]; then
      cp -f linux-i686_de.xpi ${profileDir}/extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done    
}

prepareMacProfiles() {
  echo "Creating language specific Mac profiles..."
  local appDir
  local dataDir
  local profileDir
  local jdbPlatform="JonDoBrowser-mac"

  for lang in $langs; do
    appDir=$jdbPlatform-$lang/Contents/MacOS
    dataDir=$appDir/Firefox.app/Contents/MacOS/Data
    profileDir=$jdbPlatform-$lang/Library/Application Support/Firefox/Profile
    # TODO: Maybe we should include the JDB version in the directory name.
    # Something like JonDoBrowser-x.x.x-lang
    mkdir -p $appDir/Firefox.app/Contents/Resources
    mkdir -p $dataDir/profile
    mkdir $dataDir/plugins
    mkdir -p ${profileDir}
    cp -rf profile ${profileDir}
    svn cat $svn_browser/build/langPatches/prefs_browser_$lang.js > \
      ${profileDir}/prefs.js
    mv -f ${profileDir}/places.sqlite_$lang ${profileDir}/places.sqlite
    # Cruft from the old JonDoFox-Profile...
    rm -f ${profileDir}/prefs_portable*
    rm -f ${profileDir}/places.sqlite_*
    rm -f ${profileDir}/bookmarks*
    svn cat $svn_browser/build/mac/JonDoBrowser > \
      $appDir/JonDoBrowser
    chmod +x $appDir/JonDoBrowser
    svn cat $svn_browser/build/mac/Info.plist > $jdbPlatform/Contents/Info.plist
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    if [ "$lang" = "de" ]; then
      cp -f mac_de.xpi ${profileDir}/extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done    
}

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

#TODO: Mitigation of downgrade attacks
if [ "$version" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-$version.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources ..."
  wget -t 3 ${releasePath}source/firefox-$version.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-$version.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget -t 3 ${releasePath}source/firefox-$version.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature of the sources..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
gpgVerification firefox-$version.source.tar.bz2.asc

echo "Gettings the necessary language packs..."
echo "Fetching and verifying the SHA1SUMS file..."

wget -t 3 ${releasePath}SHA1SUMS
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving SHA1SUMS, exiting..."
  exit 1
fi

wget -t 3 ${releasePath}SHA1SUMS.asc
if [ ! $? -eq 0 ]; then
  echo "Error while retrieving the SHA1SUMS signature, exiting..."
  exit 1
fi

gpgVerification SHA1SUMS.asc

echo "Retrieving the language pack(s) and verifying them..."

for platform in $platforms; do
  wget -t 3 -O ${platform}_${xpiLang}.xpi ${releasePath}${platform}/xpi/$xpiLang.xpi 
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the $xpiLang language pack for"
    echo "${platform}, continuing without it..."
    #continue
  fi 
  xpiHash1=$(grep -E "\./$platform/xpi/$xpiLang.xpi" SHA1SUMS | \
    grep -Eo "[a-z0-9]{40}")
  xpiHash2=$(sha1sum ${platform}_${xpiLang}.xpi | grep -Eo "[a-z0-9]{40}") 
  echo "$platformHash"
  if [ "$xpiHash1" = "$xpiHash2" ]; then
    echo "Verified SHA1 hash..."
  else
    echo "Wrong SHA1 hash of ${platform}_${xpiLang}.xpi, removing it" 
    rm ${platform}_${xpiLang}.xpi
  fi
done

# Now, we set up the JonDoBrowser profiles

echo "Setting up the JonDoBrowser profiles..."
echo "Fetching sources..."
svn export $svn_profile

prepareLinuxProfiles
prepareMacProfiles

cd ..

# Now, extracting, patching and building Firefox...
if [ ! -d "build" ]; then
  mkdir build 
fi

cd build && cp ../tmp/firefox-$version.source.tar.bz2 .
tar -xjvf firefox-$version.source.tar.bz2

echo
echo "Patching JonDoBrowser..."

if [ ! -d "patches" ]; then
  svn export https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build/patches \
    1>/dev/null
fi
cp patches/*.patch mozilla-release/ && cd mozilla-release

# Essentially the patch-any-src.sh from the Tor Project
for i in *patch; do patch -tp1 <$i || exit 1; done

echo "Building Firefox..."
svn cat $svn_browser/build/.mozconfig_linux-i686 > .mozconfig
make -f client.mk build

echo "Creating the final packages..."
cd linux_build && make package 
mv dist/firefox-${version}.en-US.linux-i686.tar.bz2 ../../../tmp
cd ../../../tmp && tar -xjvf firefox-${version}.en-US.linux-i686.tar.bz2 

for lang in $langs; do
  cp -rf firefox/* JonDoBrowser-$lang/App/Firefox
  tar -cf JonDoBrowser-$lang.tar JonDoBrowser-$lang
  bzip2 -z9 JonDoBrowser-$lang.tar
  mv JonDoBrowser-$lang.tar.bz2 ../
done

#Cleanup
echo "Cleaning up everything..."
cd ../
rm -rf tmp && rm -rf build

exit 0
