#!/bin/bash

# This is not recommended by the nvm maintainer, but it's a convenient hack for situations where
# every user needs access to the `node` binary.
n="`which node`"
n="${n%/bin/node}"
chmod -R 755 $n/bin/*
sudo cp -r $n/{bin,lib,share} /usr/local

