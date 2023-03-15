#!/bin/bash
git checkout dev
git pull
git checkout -b "test_1_$1"
touch "test_1_$1.txt"
git add .
git commit -m "Test $1 if action does not runs with push not in dev"
git push --set-upstream origin "test_1_$1"
