#!/bin/sh

cd buildtmp
 
if [ ! -e de.xpi ]; then
  echo "Getting the German language XPI..."
  curl --retry 3 -O  $releasePath/mac/xpi/de.xpi
  if [ ! $? -eq 0 ]; then
    echo "Error while retrieving the German language XPI, exiting..."
    exit 1
  fi
fi

cd ..
