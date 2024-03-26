#!/bin/bash

# Based on:
# https://medium.com/@lynnlin827/moving-terraform-resources-states-from-one-remote-state-to-another-c76f8b76a996
# Author: oliveirafilipe

FILE_NAME=$1.tf
TEAM_DEST=$2
DRY_RUN=true
Run () {
    if [ "$DRY_RUN" ]; then
        echo "$*"
        return 0
    fi

    eval "$@"
}

# https://www.cyberciti.biz/faq/howto-check-if-a-directory-exists-in-a-bash-shellscript/
[ ! -d "../teams/$TEAM_DEST" ] && echo "Directory ../teams/$TEAM_DEST DOES NOT exists." && exit 1

# List modules in $FILE_NAME
MODULES=`cat $FILE_NAME | perl -ne 'if(/module "(.*)"/m) { print "$1\n"}'`

if [ -z "$MODULES" ]
then
      echo "No module found in source $FILE_NAME. Exiting..."
      exit 0
fi

echo Found $(echo $MODULES | wc -w) modules in source $FILE_NAME

for module in $MODULES; do
    FOUND=`cat ../teams/$TEAM_DEST/main.tf | perl -sne 'if(/module "($modulename)"/m) { print "$1\n"}' -- -modulename="$module"`
    if [ -z "$FOUND" ]
    then
        echo "No module.$module found in target ../teams/$TEAM_DEST/main.tf. Exiting..."
        exit 0
    fi
done

FOUND=`cat ../teams/$TEAM_DEST/main.tf | perl -ne 'if(/("\.\.\/modules)/m) { print "$1\n"}'`
if [[ ! -z "$FOUND" ]]
then
    echo "Found wrong module reference in target ../teams/$TEAM_DEST/main.tf. Check the path. Exiting..."
    exit 0
fi

FOUND=`cat ../teams/$TEAM_DEST/main.tf | perl -sne 'if(/key\s*= "($modulename)"/m) { print "$1\n"}' -- -modulename="$TEAM_DEST"`
if [[ -z "$FOUND" ]]
then
    echo "Wrong backend key. Exiting..."
    exit 0
fi

# Migrate Modules
for module in $MODULES; do
    Run terraform state mv -state-out=../teams/$TEAM_DEST/terraform.tfstate module.$module module.$module
done

Run cd "../teams/$TEAM_DEST"
Run terraform init
