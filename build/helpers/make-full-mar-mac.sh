# Preparing the .mar creation
mkdir ./martmp
rm -f ./buildtmp/mozilla-release/tools/update-packaging/common.sh
rm -f ./buildtmp/mozilla-release/tools/update-packaging/make_full_update.sh
cp -f ./helpers/common.sh ./buildtmp/mozilla-release/tools/update-packaging/common.sh
cp -f ./helpers/mar ./buildtmp/mozilla-release/tools/update-packaging/mar
cp -f ./helpers/make_full_update.sh ./buildtmp/mozilla-release/tools/update-packaging/make_full_update.sh
cp -f ./helpers/createprecomplete.py ./martmp/createprecomplete.py

chmod 777 ./buildtmp/mozilla-release/tools/update-packaging/common.sh
chmod 777 ./buildtmp/mozilla-release/tools/update-packaging/mar
chmod 777 ./buildtmp/mozilla-release/tools/update-packaging/make_full_update.sh
chmod 777 ./createprecomplete.py

# Getting local directorys
mar_dest_dir=$(dirname "$0")/../
JonDo_dmg_dir=$mar_dest_dir"JonDoBrowser-0.13.dmg"
JonDo_app_dir=$mar_dest_dir
mar_complete_dir=./../../../../$mar_dest_dir"/martmp/JonDoBrowser-0.13-full_update.mar"

# Mounting JonDoBrowser to get the executable
hdiutil mount $JonDo_dmg_dir

# Creating the full update .mar
rm -rf $mar_dest_dir"JonDoBrowser.app"
cp -rf /Volumes/JonDoBrowser/JonDoBrowser.app ./martmp/
cd ./martmp/ && python ./createprecomplete.py && cd ..
cd ./buildtmp/mozilla-release/tools/update-packaging/
/bin/sh ./make_full_update.sh $mar_complete_dir ./../../../../martmp/JonDoBrowser.app

# Cleaning up
rm -rf $JonDo_app_dir
cd ./../../../../ && cp ./martmp/JonDoBrowser-0.13-full_update.mar ./JonDoBrowser-0.13-full_update.mar && rm -rf ./martmp/
hdiutil unmount /Volumes/JonDoBrowser