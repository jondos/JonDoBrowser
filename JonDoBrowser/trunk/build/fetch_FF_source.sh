#!/bin/sh

# This script fetches the sources of a Firefox release and verifies them.

# TODO: We do not want to hardcode the version.
VERSION=9.0.1

if [ ! -e "firefox-${VERSION}.source.tar.bz2" ]; then
  echo "Getting the Firefox sources for version ${VERSION}...\n"
  wget http://releases.mozilla.org/pub/mozilla.org/firefox/releases/${VERSION}/source/firefox-${VERSION}.source.tar.bz2
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the Firefox source, exiting...\n"
    exit 1
  fi
fi

if [ ! -e "firefox-${VERSION}.source.tar.bz2.asc" ]; then
  echo "Getting the signature...\n"
  wget http://releases.mozilla.org/pub/mozilla.org/firefox/releases/${VERSION}/source/firefox-${VERSION}.source.tar.bz2.asc
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the signature, exiting...\n"
    exit 1
  fi
fi

echo "Checking the signature...\n"
# TODO: Implement a more generic routine her assuming the user has not yet
# imported the Firefox key
# gpg prints the verification success message to stderr
SIGKEY=`gpg --verify firefox-${VERSION}.source.tar.bz2.asc 2>&1 | \
  grep -Eom 1 '([A-Z0-9]{4}\s*){10}' | tr -d ' '`
# TODO: Is it enough to check just the main key??
if [ "${SIGKEY}" = "9D03193D6BDC541BD796C4E47F4D66451EBCAB3A" ]; then
  echo "Successful verification!"
fi

mv firefox-${VERSION}.source.tar.bz2 ../../build_env && cd ../../build_env
tar -xjvf firefox-${VERSION}.source.tar.bz2

echo "Ready for building JonDoBrowser..."
