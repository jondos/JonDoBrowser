#!/bin/sh

cd buildtmp
 
if [ ! -e de.xpi ]; then
  echo "Getting the German language XPI...from: $releasePath/mac/de.xpi"
  curl --retry 3 -O  $releasePath/mac/de.xpi
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the German language XPI, exiting..."
    exit 1
  fi
fi

cd ..
