# Checking the arch
arch=$(uname -a)
[[ $arch == *x86_64* ]] && echo "Mac is x86_64, selecting mozconfig_mac_x86_64." && arch=$(echo "x86_64")
[[ $arch == *i386* ]] && echo "Mac is i386, selecting mozconfig_mac_i386." && arch=$(echo "i386")

echo "Preparing .mozconfig for JonDoBrowser..."
machPlatforms="mac-x86_64"; # was: "mac-x86_64 mac-i386"

for macPlatform in $macPlatforms; do
  
    cp -f ../.mozconfig .
    echo >> .mozconfig
    echo "mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/mac_build_${macPlatform}" \
      >> .mozconfig
    echo >> .mozconfig
    echo "ac_add_options --with-macos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk" \
      >> .mozconfig
    echo "ac_add_options --enable-macos-target=10.6" >> .mozconfig
    echo >> .mozconfig
    echo "HOST_CC=clang" >> .mozconfig
    echo "HOST_CXX=clang++" >> .mozconfig
    echo "RANLIB=ranlib" >> .mozconfig
    echo "AR=ar" >> .mozconfig
    echo 'AS=$CC' >> .mozconfig
    echo "LD=ld" >> .mozconfig
    echo "STRIP=\"strip\"" >> .mozconfig
    echo "CROSS_COMPILE=1" >> .mozconfig

    if [ "$macPlatform" == "mac-i386" ]; then
      # TODO: Not sure if we need everything here.
      # On 10.6.8 our building platform we only get clang 2.9 as newest clang
      # version if installed via MacPorts. But that is not recent enough to
      # build JonDoBrowser if it is based at least on FF 17. Thus, we need our
      # own compiler (3.1 is working atm)...
      echo "CC=\"clang -arch i386\"" >> .mozconfig
      echo "CXX=\"clang++ -arch i386\"" >> .mozconfig
      echo "ac_add_options --target=i386-apple-darwin10.6.0" >> .mozconfig
    else
      echo "CC=\"clang -arch x86_64\"" >> .mozconfig
      echo "CXX=\"clang++ -arch x86_64\"" >> .mozconfig
      echo "ac_add_options --target=x86_64-apple-darwin10.6.0" >> .mozconfig
    fi
    #make -f client.mk build && make -C mac_build_${macPlatform} package

done

cp .mozconfig

# Building FF
cp -f .mozconfig_mac_$arch ./buildtmp/mozilla-release/.mozconfig
cd ./buildtmp/mozilla-release/
#was: make -f client.mk build && make -C mac_build_$arch package
make -f client.mk build && make -C obj-$arch-apple-darwin13.1.0 package
# Preparing .dmg for the next Step
#was: firefox=$(ls ./mac_build_$arch/dist/ | grep \.dmg$)
# kgr: alternative: see: echo $MACHTYPE
#firefox=($ls ./obj-$arch-apple-darwin13.1.0/dist/ | grep \.dmg$)
firefox=$(ls ./obj-$MACHTYPE.1.0/dist/ | grep \.dmg)
cd .. && cd ..
cp ./buildtmp/mozilla-release/obj-$arch-apple-darwin13.1.0/dist/$firefox ./buildtmp/firefox.dmg

