#!/bin/bash

API_REPO_NAME="onepanel"

# Code bellow should not modified, 
# all the customized is placed above this comment

usage() { cat <<EOF
Usage: release.sh  -m <commit-message> [-b <branch-name>]

This commits files generated here to a target repo.

Example usage:
sr-publish -m "major changes!" -b master

Options:
  -h,--branch        branch name in a target repo (default is "develop")
  -m,--message       commit message that will be seen in a target repo
EOF
}

# default values
DOC_BRANCH="develop"

while (( $# )) ; do
flag=$1
	case $flag in
	-b|--branch)
	  DOC_BRANCH=$2
	  shift
	  ;;
	-m|--message)
	  commit_message=$2
	  shift
	  ;;
	-h|--help)
	  usage
	  exit 0
	  shift
	  ;;
	*)
	  echo "no opntion ${flag}"
	  exit 1
	  ;;
	esac
	shift
done

if [[ -z ${commit_message} ]] ; then
	echo "Must specify commit message with '-m' option. Lets keep git-log clean!"
	exit 1
fi

REPO_NAME=onedata-documentation

TMP_DIR=$(mktemp -d)
git_c="git -C $TMP_DIR"
$git_c clone  --single-branch -b $DOC_BRANCH ssh://git@git.onedata.org:7999/vfs/${REPO_NAME}.git ${TMP_DIR}

SRC_GITBOOK=generated/gitbook
PATH_IN_GITBOOK=${TMP_DIR}/doc/advanced/rest/${API_REPO_NAME}
$git_c rm -r $PATH_IN_GITBOOK/*
mkdir -p $PATH_IN_GITBOOK
cp -r $SRC_GITBOOK/* $PATH_IN_GITBOOK/

SRC_SWAGGER=swagger.json
PATH_IN_GITBOOK=${TMP_DIR}/doc/swagger/${API_REPO_NAME}
$git_c rm -r $PATH_IN_GITBOOK/*
mkdir -p $PATH_IN_GITBOOK
cp -r $SRC_SWAGGER $PATH_IN_GITBOOK/

$git_c add -A
$git_c diff 
$git_c commit -m "${API_REPO_NAME} swag. api: $commit_message"
$git_c push

rm -rf $TMP_DIR 
