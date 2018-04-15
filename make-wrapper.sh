#!/bin/sh

if [ "$1" == "install" ]; then
    # xcode's archive action uses install, but leveldb doesn't like it
    make
else
    make $*
fi