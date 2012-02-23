#!/bin/bash

# This script fetches the latest sources of a Firefox release and verifies them.

# The first grep makes sure we really get the latest firefox version and not
# someting else of the html page. The second grep finally extracts the latest
# version.
version=$(wget -qO - http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/source | \
  grep -Eom 1 'firefox-[0-9]{2}\.[0-9](\.[0-9]).source.tar.bz2' | tail -n1 |\
   grep -Eom 1 '[0-9]{2}\.[0-9](\.[0-9])')

#TODO: Mitigation of downgrade attacks
if [ "$version" = "" ]; then
  echo "We got no version extracted, thus exiting..."
  exit 1
elif [ ! -e "firefox-$version.source.tar.bz2" ]; then
  echo "Getting the latest Firefox sources ..."
  wget http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/source/firefox-$version.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox sources, exiting..."
    exit 1
  fi
fi

if [ ! -e "firefox-$version.source.tar.bz2.asc" ]; then
  echo "Getting the signature..."
  wget http://releases.mozilla.org/pub/mozilla.org/firefox/releases/latest/source/firefox-$version.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting..."
    exit 1
  fi
fi

echo "Checking the signature..."
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
sigkey=$(gpg --verify firefox-$version.source.tar.bz2.asc 2>&1 | \
  grep -Eom 1 '([A-Z0-9]{4}\s*){10}' | tr -d ' ')

if [ "$sigkey" = "247CA658AA95F6171EB0F13EA7D75CC7C52175E2" ]; then
  echo "Successful verification!"
fi

mv firefox-$version.source.tar.bz2 ../../build_env && cd ../../build_env
tar -xjvf firefox-$version.source.tar.bz2

echo
echo "Patching JonDoBrowser..."

svn co https://svn.jondos.de/svnpub/JonDoBrowser/trunk/build/patches \
  1>/dev/null
cp patches/*.patch mozilla-release/ && cd mozilla-release

# Essentially the patch-any-src.sh from the Torproject
for i in *patch; do patch -tp1 <$i || exit 1; done

exit 0
