#!/bin/bash

rm -rf docs

jazzy \
  --config .jazzy.yaml \
  --output "docs/docs"
