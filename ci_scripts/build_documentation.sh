#!/bin/bash

mv docs/index.html .

rm -rf docs

jazzy \
  --config .jazzy.yaml \
  --output "docs/docs"

mv index.html docs/index.html
