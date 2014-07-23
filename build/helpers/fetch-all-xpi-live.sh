#!/bin/sh

releasePath=http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/latest-24.0esr

cd buildtmp

wget -t 3 $releasePath/linux-i686/xpi/fr.xpi
wget -t 3 $releasePath/linux-i686/xpi/it.xpi
wget -t 3 $releasePath/linux-i686/xpi/pl.xpi
wget -t 3 $releasePath/linux-i686/xpi/ru.xpi
wget -t 3 $releasePath/linux-i686/xpi/es-ES.xpi
wget -t 3 $releasePath/linux-i686/xpi/sv-SE.xpi

cd ..
