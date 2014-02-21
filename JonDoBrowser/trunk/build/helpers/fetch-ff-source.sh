#!/bin/sh

mozKey=5445390EF5D0C2ECFB8A6201057CC3EB15A0A4BC
releasePath=http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr

svnXPI=https://svn.jondos.de/svnpub/JonDoFox_Extension/trunk/xpi/jondofoxBrowser.xpi
svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile

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


gpgVerification firefox-${ffVersion}esr.source.tar.bz2.asc

echo "Fetching JonDoFox profile..."
svn export $svnProfile

echo "Fetching JonDoBrowser XPI..."
svn export $svnXPI

cd ..
