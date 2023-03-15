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
git checkout -b "test_4_$1"
git tag -a v2.$1 -m "Test if action not runs with new pushed tag in not dev"
git push origin v2.$1

git checkout dev
git pull
git tag -a v1.$1 -m "Test if action runs with new pushed tag in dev"
git push origin v1.$1


