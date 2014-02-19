#!/bin/sh

svnXPI=https://svn.jondos.de/svnpub/JonDoFox_Extension/trunk/xpi/jondofoxBrowser.xpi
svnProfile=https://svn.jondos.de/svnpub/JonDoFox_Profile/trunk/full/profile

cd buildtmp

echo "Fetching JonDoFox profile..."
svn export $svnProfile

echo "Fetching JonDoBrowser XPI..."
svn export $svnXPI

cd ..
