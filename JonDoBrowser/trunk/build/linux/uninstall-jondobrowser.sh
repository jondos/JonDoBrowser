#!/bin/bash

if [ -w "/usr/local" ]
   then
      echo "Remove JonDoBrowser"
      rm -r /opt/JonDoBrowser

      echo "Remove application starter and icons in /usr/local"
      rm /usr/local/bin/jondobrowser
      rm /usr/local/share/pixmaps/jondobrowser.png
      rm /usr/local/share/applications/jondobrowser.desktop

      if [ -x "/usr/bin/update-menus" ]
          then
             echo "Update application menus"
             /usr/bin/update-menus
      fi

   else
      echo "Keine Berechtigung zur Installation. Führen Sie die Installation als root durch oder nutzen Sie \"sudo\"."
      exit 1;
fi 
