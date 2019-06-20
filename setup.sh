#!/bin/bash

echo '▸ Installing dependencies for Standard Integration';

cd Example;

if [[ -e Cartfile.resolved ]]; then
  rm Cartfile.resolved;
fi

if ! command -v carthage > /dev/null; then
  echo ''
  echo 'ERROR: Please install carthage before running setup.sh:'
  echo 'https://github.com/Carthage/Carthage#installing-carthage';
  exit 1;
fi

carthage bootstrap --platform ios;

echo '▸ Finished installing dependencies for Standard Integration';
