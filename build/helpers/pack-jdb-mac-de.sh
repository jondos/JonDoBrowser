generateDmgImage() {
  # Function for creating JonDoBrowser dmg on Mac OS X based on:
  # http://stackoverflow.com/questions/96882/how-do-i-create-a-nice-looking-
  # dmg-for-mac-os-x-using-command-line-tools

  # To make this work you need to set source and $backgroundPictureName.
  # The $source directory should contain the .background directory with the
  # background image inside.
  #
  # Adapted for JonDoBrowser's needs by Georg Koppen, JonDos GmbH 2012.

  # We want to have just "JonDoBrowser" shown.
  applicationName="JonDoBrowser.app"

  # insert "$arch" !!!
  finalDMGName="JonDoBrowser_de.dmg"

  # TODO GeKo: Why does the backslash as a line delimiter not work but result in an error?
  # UDBZ?
  hdiutil create -srcfolder "JDB" -volname "JonDoBrowser" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 200000k JDB.temp.dmg

  # TODO Geko: Why does the backslash as a line delimiter not work but result in an error?
  device=$(hdiutil attach -readwrite -noverify -noautoopen "JDB.temp.dmg" | egrep '^/dev/' | sed 1q)
  
  chmod -Rf go-w /Volumes/"JonDoBrowser"
  chmod 777 /Volumes/JonDoBrowser/JonDoBrowser.app/Contents/MacOS/JonDoBrowser

  echo '
    tell application "Finder"
      tell disk "'JonDoBrowser'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 128
           set background picture of theViewOptions to file ".background:'background.png'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'JonDoBrowser.app'" of container window to {100, 120}
           set position of item "Applications" of container window to {375, 120}
           close
           open
           update without registering applications
           delay 5
           eject
       end tell
     end tell
  ' | osascript

  chmod -Rf go-w /Volumes/"JonDoBrowser"
  sync
  sync
  hdiutil detach ${device}
  hdiutil convert "JDB.temp.dmg" -format UDBZ -o "${finalDMGName}"
  rm "JDB.temp.dmg"
}

# Unpacking the .dmg
./buildtmp/mozilla-release/build/package/mac_osx/unpack-diskimage ./buildtmp/firefox.dmg testing buildtmp

mkdir ./JonDoBrowser-de
mkdir ./JonDoBrowser-de/Contents
mkdir ./JonDoBrowser-de/Contents/MacOS
mkdir ./JonDoBrowser-de/Library
mkdir ./JonDoBrowser-de/Library/Application\ Support
mkdir ./JonDoBrowser-de/Library/Application\ Support/Firefox
mkdir ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles
mkdir ./JonDoBrowser-de/Contents/Resources

#cp -Rf ./buildtmp/profile/ ./JonDoBrowser-en-US/Library/Application\ Support/Firefox/profiles/profile

# Coose the bookmarks for de - this is probably STILL wrong
mv -f ./JonDoBrowser/Library/Application\ Support/Firefox/profiles/profile/places.sqlite ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite
rm -f ./JonDoBrowser/Library/Application\ Support/Firefox/profiles/profile/places.sqlite

cp -Rf ./buildtmp/JonDoBrowser.app/ ./JonDoBrowser-de/Contents/MacOS/Firefox.app

cp ./mac/Info.plist ./JonDoBrowser-de/Contents/
cp ./mac/jondobrowser.icns ./JonDoBrowser-de/Contents/Resources/
cp ./mac/JonDoBrowser_de ./JonDoBrowser-de/Contents/MacOS/JonDoBrowser

# replace search-plugins
rm ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/*.xml
cp searchplugins/common/*.xml ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/
cp searchplugins/de/*.xml ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/

# Creating JonDoBrowser.app
mv ./JonDoBrowser-de ./JonDoBrowser.app


# Creating JonDoBrowser.app
mv ./JonDoBrowser-de ./JonDoBrowser.app

# -- added, kgr, for de-version
profileDir=./JondoBrowser-de/Library/Application\ Support/Firefox/Profiles/profile
echo $profileDir
read -p "Press [Enter] key to go on setting de.xpi..."
cp -f ./buildtmp/de.xpi "$profileDir"/extensions/langpack-de@firefox.mozilla.org.xpi

echo "user_pref(\"extensions.langpack-de@firefox.mozilla.org.update.enabled\", false);" >> "$profileDir"/prefs.js 

# -- end addition

# Preparing background image for final .dmg
if [ ! -d "JDB" ]; then
      mkdir JDB
      cd JDB && mkdir .background && cd .background
      cp ../../mac/background-de.png ./background.png
      cd ../..
fi

# Copy JonDoBrowser.app inside JDB
mv ./JonDoBrowser.app ./JDB/
chmod -Rf go-w ./JDB
chmod 777 ./JDB/JonDoBrowser.app/Contents/MacOS/JonDoBrowser

# Checking the arch
arch=$(uname -a)
[[ $arch == *x86_64* ]] && arch=$(echo "x86_64")
[[ $arch == *i386* ]] && arch=$(echo "i386")

# Generate new .dmg
generateDmgImage $arch de
