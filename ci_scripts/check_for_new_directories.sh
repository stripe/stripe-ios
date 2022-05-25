#!/bin/bash

# Prints a list of directories that have been modified between the two commits

commit1=$1
commit2=$2

diff <(git ls-tree -r -t "$commit1" | grep " tree " | sed 's/.*\t//') <(git ls-tree -r -t "$commit2" | grep " tree " | sed 's/.*\t//')
