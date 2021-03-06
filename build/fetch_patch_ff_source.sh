#!/bin/bash

# This script fetches the latest sources of a Firefox release and verifies them.

# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.

# We only need the german language pack currently as english is the default
xpiLang=de
platforms="linux-i686 mac win32"
mozKey=247CA658AA95F6171EB0F13EA7D75CC7C52175E2 
releasePath=http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/
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

cd ..

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

exit 0
