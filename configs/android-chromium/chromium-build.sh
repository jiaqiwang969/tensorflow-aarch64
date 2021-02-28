#!/bin/bash

set -ex

setup_depottools() {
  sudo apt-get update
  rm -rf depot_tools
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  export PATH=${PWD}/depot_tools:${PATH}
}

setup_chromium() {
  rm -rf chromium
  mkdir chromium
  cd chromium
  test -d src || fetch --nohooks android
}

sync_source() {
  yes | gclient sync
}

install_deps() {
  sudo ./src/build/install-build-deps.sh --no-syms --no-chromeos-fonts --no-prompt
  sudo ./src/build/install-build-deps-android.sh --no-prompt
}

setup_buildenv() {
  rm -rf out
  case "${ARGS}" in
    gcc_arm)
      gn gen out/Default --args="target_os=\"android\" target_cpu=\"arm\" is_debug=true is_component_build=true is_clang=false symbol_level=1 enable_incremental_javac=true"
      ;;
    gcc_arm64)
      gn gen out/Default --args="target_os=\"android\" target_cpu=\"arm64\" is_debug=true is_component_build=true is_clang=false symbol_level=1 enable_incremental_javac=true"
      ;;
    clang_arm)
      gn gen out/Default --args="target_os=\"android\" target_cpu=\"arm\" is_debug=true is_component_build=true is_clang=true symbol_level=1 enable_incremental_javac=true"
      ;;
    clang_arm64)
      gn gen out/Default --args="target_os=\"android\" target_cpu=\"arm64\" is_debug=true is_component_build=true is_clang=true symbol_level=1 enable_incremental_javac=true"
      ;;
  esac
}

build_chromium() {
  . build/android/envsetup.sh
  ninja -C out/Default chrome_public_apk
}

apply_patches() {
  cd ..
  rm -rf chromium-patchsets
  git clone http://android-review.linaro.org/chromium-patchsets
  cd chromium-patchsets
  pw=${PWD}
  export patches=$(find . -iname "*.patch" | sort)
  for patch in ${patches}; do echo "applying $patch"; project=$(dirname "${patch}"); cd ../src/"${project}";rm -rf .git/rebase-apply; git am "${pw}"/"${patch}"; cd -; done
  cd ../src/
  rm -rf "${pw}"
}

main() {
  setup_depottools
  setup_chromium
  sync_source
  install_deps
  cd src
  git reset --hard
  git clean -fdx
  sync_source
  git reset --hard
  git rebase-update
  sync_source
  apply_patches
  setup_buildenv
  echo ${PWD}
  export PATH=${PATH}:${PWD}/third_party/android_tools/ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin/
  build_chromium
  commit=`git log -1 | grep commit | cut -d' ' -f2`
  cp /home/buildslave/srv/${JOB_NAME}/configs/android-chromium/manifest-template.xml out/Default/apks/pinned-manifest.xml
  sed -i "s/%%REVISION%%/${commit}/g" out/Default/apks/pinned-manifest.xml
}

main "$@"
