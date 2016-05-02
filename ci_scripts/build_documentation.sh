#!/bin/bash

rm -rf docs

./jazzy/bin/jazzy \
  --config .jazzy.yaml \
  --output "docs"
