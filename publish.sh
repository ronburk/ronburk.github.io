#!/bin/bash

# publish.sh - commit/publish the GitHub pages

# offers to commit and push. Skip commit with a "n".
# skip push with Ctrl-C.

# YesNo(): ask user yes/no question, return true if yes
function YesNo() {
    declare -l Answer    # make a lower-casing variable
    while true; do
        read -p "$1 [Y/n]: " Answer
        Answer=${Answer:-y}
        case "$Answer" in
            "y"|"yes"|"")
                Answer="y"
                break
                ;;
            "n"|"no")
                Answer="n"
                break
                ;;
        esac
    done
    if [ "$Answer" == "y" ]; then
        return 0
    else
        return 1
    fi
}


# show git status
git status
# check for changed files
if git diff-index --quiet HEAD --; then
    echo "No uncommitted changes."
elif YesNo "Commit changes?"; then
    read -p "Enter commit message: " message
    git commit -a -m "$message"
fi

if YesNo "Push changes?"; then
    git push -u origin master
fi

