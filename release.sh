#!/bin/bash

if [[ $# -lt 1 ]]; then
  DOC_BRANCH="develop"
else
  DOC_BRANCH=$1
fi

REPO_NAME=onedata-documentation

TMP_DIR=$(mktemp -d)
git_c="git -C $TMP_DIR"
$git_c clone  --single-branch -b $DOC_BRANCH ssh://git@git.plgrid.pl:7999/vfs/${REPO_NAME}.git ${TMP_DIR}
SUMMARY=${TMP_DIR}/SUMMARY.md

SRC_GITBOOK=generated/gitbook
PATH_IN_GITBOOK=${TMP_DIR}/doc/advanced/rest/onepanel
$git_c rm -r $PATH_IN_GITBOOK/*
mkdir -p $PATH_IN_GITBOOK
cp -r $SRC_GITBOOK/* $PATH_IN_GITBOOK/

SRC_SWAGGER=swagger.json
PATH_IN_GITBOOK=${TMP_DIR}/doc/swagger/onepanel
$git_c rm -r $PATH_IN_GITBOOK/*
mkdir -p $PATH_IN_GITBOOK
cp -r $SRC_SWAGGER/* $PATH_IN_GITBOOK/

$git_c add -A
$git_c diff 
$git_c commit -m "updated onepanel swagger api"
$git_c push

rm -rf $TMP_DIR 
