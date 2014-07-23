#!/bin/bash


#
# --- initialize / export  basic vars ---
#

jdbVersion="0.17"

mozKey=5445390EF5D0C2ECFB8A6201057CC3EB15A0A4BC
export releasePath=http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-24.0esr
# bash does set & export vars, no need for: export $releasePath

svnXPI=https://svn.jondos.de/svnpub/JonDoFox_Extension/trunk/xpi/jondofoxBrowser.xpi
svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile

# set $arch if none else has set it yet
if [ -n "$arch" ]; then export arch=x86_64; fi;

 

#
# --- get the FF sources & determine version & get signatures ---
#

cd buildtmp

ffVersion=$(curl -L --retry 3 -so - $releasePath/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9])*esr.source.tar.bz2' | tail -n1 | \
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])*')

if [ "$ffVersion" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-${ffVersion}esr.source.tar.bz2" ]; then
  echo "Getting the latest Firefox ESR sources (version $ffVersion)..."
  curl --retry 3 -O $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-${ffVersion}esr.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  curl --retry 3 -O $releasePath/source/firefox-${ffVersion}esr.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi



# 
# --- verify ff-sources ---
#

# define function
gpgVerification() {
  sigKey=$(gpg --verify $1 2>&1 | tail -n1 | tr -d ' ' | \
           sed 's/.*[^A-F0-9]\([A-F0-9]\{40\}\)/\1/g')

  if [ "$sigKey" = "$mozKey" ]; then
    echo "Successful verification!"
  else
    echo "Wrong signature, aborting..."
    rm firefox-${ffVersion}esr.source.tar.bz2
    exit 1
  fi
}

# now call it
gpgVerification firefox-${ffVersion}esr.source.tar.bz2.asc



#
# -- fetch jdb xpi ---
# 

echo "Fetching JonDoBrowser XPI..."
svn export $svnXPI

echo "Fetching JonDoFox profile..."
svn export $svnProfile
rm -f ./profile/prefs_portable*
# search plugins are part of JonDoBrowser
rm -r ./profile/searchplugins
# We do not need ProfileSwitcher in our JonDoBrowser, thus removing it.
rm -rf ./profile/extensions/\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4\}.xpi

# Remove the JonDoFox-XPI for JonDoFox and replace it with JDB-XPI
rm ./profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi
cp ./jondofoxBrowser.xpi ./profile/extensions/\{437be45a-4114-11dd-b9ab-71d256d89593\}.xpi

echo "user_pref(\"extensions.jondofox.browser_version\", \"${jdbVersion}\");" >> profile/prefs.js
chmod -R ugo-x,u+rwX,go+rX,go-w profile

cd ..

