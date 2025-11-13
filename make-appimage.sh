#!/bin/sh

set -eu

export ARCH=$(uname -m)
export VERSION=$(cat ./dist/version)
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=PATH_OR_URL_TO_ICON
export DESKTOP=PATH_OR_URL_TO_DESKTOP_ENTRY

# Deploy dependencies
quick-sharun /PATH/TO/BINARY_AND_LIBRARIES_HERE

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# release artifact and make appname file
mv -v ./*.AppImage* ./dist
awk -F'=' '/^Name=/ {gsub(/ /,"_",$2); print $2; exit}' ./AppDir/*.desktop > ./dist/appname
