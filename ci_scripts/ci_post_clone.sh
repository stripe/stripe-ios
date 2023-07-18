#!/bin/bash

wget https://github.com/tuist/tuist/releases/download/`cat .tuist-version`/tuist.zip
unzip tuist.zip -d tuist-bin
./tuist-bin/tuist generate -n