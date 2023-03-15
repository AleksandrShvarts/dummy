#!/bin/bash
git checkout dev
git pull
git checkout -b "test_1_$1"
touch "test_1_$1.txt"
git add .
git commit -m "Test $1 if action does not runs with push not in dev"
git push --set-upstream origin "test_1_$1"

git checkout dev
git pull
touch "test_2_$1.txt"
git add .
git commit -m "Test $1 if action runs with push in dev"
git push --set-upstream origin dev

git checkout dev
git pull
git tag -a v1.$1 -m "test 3: release 1.$1"
git push origin v1.$1
