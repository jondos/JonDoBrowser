#!/bin/bash
svnDir=https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build
langs="en de"
title="JonDoBrowser"
size="200000"
source="JDB"
backgroundPictureName="background.png"

generateDmgImage() {
  # TODO: LICENSE
  # Function for creating JonDoBrowser dmg files on Mac OS X.
  # Originally by Arturo Filasto' 2011 for the TorBrowserBundle.
  #
  # To make this work you need to set the $source and $backgroundPictureName
  # The $source directory should contain the .background directory with the
  # background image inside.
  #
  # based on:
  # http://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-dmg-for-mac-os-x-using-command-line-tools
  # Adapted for JonDoBrowser's needs by Georg Koppen, JonDos GmbH 2012.

  applicationName="JonDoBrowser-mac-$1.app"
  finalDMGName="JonDoBrowser-$1.dmg"
  # TODO GeKo: Why does the backslash as a line delimiter not work but result in an error?
  # UDBZ?
  hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k JDB.temp.dmg

  # TODO Geko: Why does the backslash as a line delimiter not work but result in an error?
  device=$(hdiutil attach -readwrite -noverify -noautoopen "JDB.temp.dmg" | egrep '^/dev/' | sed 1q | awk '{print $1}')

  # TODO The dmg image creation is giving errors in lines 48 and 51. Needs to
  # get fixed with the background imgage...
  echo '
    tell application "Finder"
      tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 100
           set background picture of theViewOptions to file ".background:'${backgroundPictureName}'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "Applications" of container window to {380, 160} 
           close
           open
           set position of item "JonDoBrowser.app" of container window to {120, 160}
           close
           open
           set position of item "JonDoBrowser.app" of container window to {120, 160}
           update without registering applications
           delay 5
       end tell
     end tell
  ' | osascript

  chmod -Rf go-w /Volumes/"${title}"
  sync
  sync
  hdiutil detach ${device}
  hdiutil convert "JDB.temp.dmg" -format UDBZ -o "${finalDMGName}"
  rm "$source.temp.dmg"
}

svn cat $svnDir/.mozconfig_mac > build/mozilla-release/.mozconfig

cd build/mozilla-release
make -f client.mk build
cd ../..
for lang in $langs; do
  appDir=JonDoBrowser-mac-$lang/Contents/MacOS
  cp -rf build/mozilla-release/mac_build/dist/Firefox.app/* $appDir/Firefox.app 
  mv JonDoBrowser-mac-$lang JonDoBrowser-mac-$lang.app
  # Preparing everything for generating the dmg image...
  if [ ! -d $source ]; then
    mkdir $source
    cd $source && mkdir .background     
    # TODO: We need to get that out of the repo first...
    cp ../background.png .background
    cd ..
  fi
  mv JonDoBrowser-mac-$lang.app $source/
  generateDmgImage $lang
  rm -rf $source/JonDoBrowser-mac-$lang.app
done

rm -rf $source
#rm -rf build/mozilla-release
