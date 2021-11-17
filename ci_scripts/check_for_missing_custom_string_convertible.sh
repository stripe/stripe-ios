#!/bin/bash

EXIT_CODE=0

git diff --quiet --exit-code -- "*Enums+CustomStringConvertible.swift"
if [[ $? -ne 0 ]]; then
  echo -e "\t\033[0;31mMissing CustomStringConvertible conformance found\nRun `ruby ./ci_scripts/generate_objc_enum_string_values.rb` to autogen missing conformance.\033[0m"
  EXIT_CODE=1
fi
exit $EXIT_CODE
