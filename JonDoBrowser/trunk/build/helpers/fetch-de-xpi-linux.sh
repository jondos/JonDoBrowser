#!/bin/sh

releasePath=http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-24.0esr

cd buildtmp

wget -t 3 $releasePath/linux-i686/xpi/de.xpi

cd ..
