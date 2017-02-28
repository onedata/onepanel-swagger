#!/usr/bin/env bash

set -e

SERVICE=onepanel
#
# Language of the client repo (e.g. js, python, ...)
#
LANGUAGE=$1

TARGET_DIRECTORY=$(mktemp -d)
WORK_DIRECTORY=$PWD

declare -A releases

#
# Maps branch names to release names
#
releases["release/3.0.0-rc9"]="3.0.0-rc9"
releases["release/3.0.0-rc10"]="3.0.0-rc10"
releases["release/3.0.0-rc11"]="3.0.0-rc11"
releases["release/3.0.0-rc12"]="3.0.0-rc12"

git clone ssh://git@git.plgrid.pl:7999/vfs/${SERVICE}-${LANGUAGE}-client.git ${TARGET_DIRECTORY}

rm -rf packages
for release_branch in "${!releases[@]}"; do

    git checkout $release_branch

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0

    cd $TARGET_DIRECTORY && git checkout $release_branch && cd $WORK_DIRECTORY

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:ID-2fc8126ac8 \
        generate -i ./swagger.json -l ${LANGUAGE} \
        -o ${TARGET_DIRECTORY} -c ${LANGUAGE}-config.json \
        -DprojectVersion="${releases[$release_branch]}"

    cd $TARGET_DIRECTORY && git add . && git commit -a -m "Auto update" && cd $WORK_DIRECTORY

done

git checkout master
