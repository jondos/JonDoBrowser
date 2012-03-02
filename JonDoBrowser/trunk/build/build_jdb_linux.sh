#!/bin/bash

svn_profile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile
svn_browser=https://svn.jondos.de/svnpub/JonDoBrowser/trunk
langs="en-US de"

prepareProfiles() {
  echo "Creating language specific profiles..."

  for lang in $langs; do
    local profileDir
    profileDir=JonDoBrowser-$lang/Data/profile/
    mkdir -p JonDoBrowser-$lang/App/Firefox
    mkdir JonDoBrowser-$lang/Data
    cp -rf profile JonDoBrowser-$lang/Data
    svn cat $svn_browser/build/langPatches/prefs_browser_$lang.js > \
      ${profileDir}prefs.js
    mv -f ${profileDir}places.sqlite_$lang ${profileDir}places.sqlite
    # Cruft from the old JonDoFox-Profile...
    rm -f ${profileDir}prefs_portable*
    rm -f ${profileDir}places.sqlite_*
    rm -f ${profileDir}bookmarks*
    # Copying the language xpi to get other language strings than the en-US
    # ones.
    if [ "$lang" = "de" ]; then
      cp -f linux-i686_de.xpi ${profileDir}extensions/langpack-de@firefox.mozilla.org.xpi
    fi
  done    
}

if [ ! -d "tmp" ]; then
  mkdir tmp
fi
cd tmp

echo "Setting up the JonDoBrowser profiles..."
echo "Fetching sources..."
svn export $svn_profile

prepareProfiles 

echo "Building Firefox..."
cd ../build/mozilla-release
#system=$(./build/autoconf/config.guess)
#./configure && make -f client.mk build
#echo "Creating the final packages..."
#cd obj-$system && make package 
#mv dist/firefox-[0-9][0-9].[0-9]*.tar.bz2 ../../../
#cd ../../../ && tar -xjvf firefox-[0-9][0-9].[0-9]*.tar.bz2 
