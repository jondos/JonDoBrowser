#!/bin/bash

if [ ! -d Work ]
  then
    cp -r Data Work
    chmod -R ugo-x,u+rwX,go-rw Work
fi

./App/firefox/firefox -profile ./Work/profile -no-remote
