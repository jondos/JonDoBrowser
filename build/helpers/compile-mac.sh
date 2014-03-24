# Checking the arch
arch=$(uname -a)
[[ $arch == *x86_64* ]] && echo "Mac is x86_64, selecting mozconfig_mac_x86_64." && arch=$(echo "x86_64")
[[ $arch == *i386* ]] && echo "Mac is i386, selecting mozconfig_mac_i386." && arch=$(echo "i386")

# Building FF
cp -f .mozconfig_mac_$arch ./buildtmp/mozilla-release/.mozconfig
cd ./buildtmp/mozilla-release/
make -f client.mk build && make -C mac_build_$arch package

# Preparing .dmg for the next Step
firefox=$(ls ./mac_build_x86_64/dist/ | grep \.dmg$)
cd .. && cd ..
cp ./buildtmp/mozilla-release/mac_build_x86_64/dist/$firefox ./firefox.en-US.dmg