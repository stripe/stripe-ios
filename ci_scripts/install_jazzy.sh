#!/bin/bash

# Install jazzy

rm -rf jazzy
git clone --depth 1 --branch master https://github.com/realm/jazzy/
cd jazzy
bundle install
cd ..
