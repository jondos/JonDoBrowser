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
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Programme"}
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
  #echo $(device)
  #read -p "Check device name"
  #hdiutil detach ${device}
  hdiutil convert "JDB.temp.dmg" -format UDBZ -o "${finalDMGName}"
  #rm "JDB.temp.dmg"
}

# get de.xpi, rename it to extensions/langpack-de@firefox.mozilla.org.xpi and place it right
cd buildtmp
if [ ! -e de.xpi ]; then
  echo "Getting the German language XPI..." 
  # fetched from explicit URL, if not yet in latest-esr 
  #curl --retry 3 -O  ftp://ftp.mozilla.org/pub/firefox/releases/24.4.0esr/linux-i686/xpi/de.xpi
  curl --retry 3 -O  http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr/mac/xpi/de.xpi
  # mkdir ./profile/extensions/langpack-de@firefox.mozilla.org.xpi
  cp -f ./de.xpi ./profile/extensions/langpack-de@firefox.mozilla.org.xpi
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the German language XPI, exiting..."
    exit 1
  fi
fi

cd ..

#read -p "Check if de.XPI is there in buildtmp/profile/extensions/ ... named langpack-de@firefox.mozilla.org.xpi"


# Unpacking the .dmg into ./buildtmp
#./buildtmp/mozilla-release/build/package/mac_osx/unpack-diskimage ./firefox.en-US.dmg testing buildtmp
./buildtmp/mozilla-release/build/package/mac_osx/unpack-diskimage ./firefox.en-US.dmg ./buildtmp/testing ./buildtmp
read -p "Check unpacking..."
mkdir ./JonDoBrowser-de
mkdir ./JonDoBrowser-de/Contents
mkdir ./JonDoBrowser-de/Contents/MacOS
mkdir ./JonDoBrowser-de/Library
mkdir ./JonDoBrowser-de/Library/Application\ Support
mkdir ./JonDoBrowser-de/Library/Application\ Support/Firefox
mkdir ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles
mkdir ./JonDoBrowser-de/Contents/Resources

cp -Rf ./buildtmp/profile/ ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile

cp -Rf ./buildtmp/JonDoBrowser.app/ ./JonDoBrowser-de/Contents/MacOS/Firefox.app


# Coose the bookmarks for de - this is probably STILL wrong
#mv -f ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite
#rm -f ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite

# Coose the bookmarks for en-US
read -p "Check bookmarks / shortcuts ..."
mv -f ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite_de ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite
rm -f ./JonDoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/places.sqlite_de
read -p "Check bookmarks / shortcuts #2..."

cp -Rf ./buildtmp/JonDoBrowser.app/ ./JonDoBrowser-de/Contents/MacOS/Firefox.app

cp ./mac/Info.plist ./JonDoBrowser-de/Contents/
cp ./mac/jondobrowser.icns ./JonDoBrowser-de/Contents/Resources/
cp ./mac/JonDoBrowser_de ./JonDoBrowser-de/Contents/MacOS/JonDoBrowser

# replace search-plugins, german version includes searchplugins/de too
rm ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/*.xml
cp searchplugins/common/*.xml ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/
cp searchplugins/de/*.xml ./JonDoBrowser-de/Contents/MacOS/Firefox.app/Contents/MacOS/browser/searchplugins/

# Creating JonDoBrowser.app
mv ./JonDoBrowser-de ./JonDoBrowser.app


# Creating JonDoBrowser.app
#mv ./JonDoBrowser-de ./JonDoBrowser.app

# -- added, kgr, for de-version
#profileDir=./JondoBrowser-de/Library/Application\ Support/Firefox/Profiles/profile
#echo $profileDir
#read -p "Press [Enter] key to go on setting de.xpi..."
#cp -f ./buildtmp/de.xpi JondoBrowser-de/Library/Application\ Support/Firefox/profiles/profile/extensions/langpack-de@firefox.mozilla.org.xpi
#echo "user_pref(\"extensions.langpack-de@firefox.mozilla.org.update.enabled\", true);" >> JondoBrowser-de/Library/Application\ Support/Firefox/profiles/prefs.js 
#searchengines
#read -p "Check de.xpi... [Enter] "

# -- end addition

# Preparing background image for final .dmg
if [ ! -d "JDB" ]; then
      mkdir JDB
      cd JDB && mkdir .background && cd .background
      cp ../../mac/background-de.png ./background.png
      cd ../..
fi

# Copy JonDoBrowser.app inside JDB
cp -R ./JonDoBrowser.app ./JDB/
chmod -Rf go-w ./JDB
chmod 777 ./JDB/JonDoBrowser.app/Contents/MacOS/JonDoBrowser

# Checking the arch
arch=$(uname -a)
[[ $arch == *x86_64* ]] && arch=$(echo "x86_64")
[[ $arch == *i386* ]] && arch=$(echo "i386")

# Generate new .dmg
generateDmgImage $arch de
