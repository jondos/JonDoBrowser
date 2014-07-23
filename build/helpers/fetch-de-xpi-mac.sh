#!/bin/sh

cd buildtmp

if [ ! -e de.xpi ]; then
  echo "Getting the German language XPI..."
  # (old one) curl --retry 3 -O  http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-esr/mac/xpi/de.xpi
  curl --retry 3 -O  ftp://ftp.mozilla.org/pub/firefox/releases/24.7.0esr/linux-i686/xpi/de.xpi
  mkdir ./profile/extensions/langpack-de@firefox.mozilla.org.xpi
  mv -f ./de.xpi ./profile/extensions/langpack-de@firefox.mozilla.org.xpi
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the German language XPI, exiting..."
    exit 1
  fi
fi

cd ..
