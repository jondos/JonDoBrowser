#!/bin/bash

if [ -w "/usr" ]
   then
      echo "Install JonDoBrowser in /opt/JonDoBrowser"
      if [ -e "/opt/JonDoBrowser" ]
        then
           rm -r /opt/JonDoBrowser
      fi
      install -d /opt/JonDoBrowser
      cp -r App /opt/JonDoBrowser/
      cp -r Data /opt/JonDoBrowser/

      echo "Install application starter and icons in /usr/local"
      install -d /usr/local/bin
      cp -f misc/jondobrowser /usr/local/bin/
      install -d /usr/local/share/pixmaps
      cp -f misc/jondobrowser.png /usr/local/share/pixmaps/
      install -d /usr/local/share/applications
      cp -f misc/jondobrowser.desktop /usr/local/share/applications/

      if [ -d /usr/share/hunspell ]
        then
          echo "Create link for hunspell dictionaries"
          rm -r /opt/JonDoBrowser/App/firefox/dictionaries
          ln -s /usr/share/hunspell /opt/JonDoBrowser/App/firefox/dictionaries
      fi

      if [ -x "/usr/bin/update-menus" ]
          then
             echo "Update application menus"
             /usr/bin/update-menus
      fi

   else
      echo "No write permissions. Please become root first or use \"sudo\"."
      exit 1;
fi 
