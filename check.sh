#!/bin/bash
if [[ "" == $(git merge-base --is-ancestor $1 HEAD) ]];
then echo "true"
else echo "false"
fi
# echo $(git merge-base --is-ancestor 110564f8eb08e259397d2f3fb807e198d7172449 HEAD)

