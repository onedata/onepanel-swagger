#!/usr/bin/env bash

set -e

SERVICE=onepanel
#
# Language of the client repo (e.g. js, python, ...)
#
LANGUAGE=$1
TARGET_DIRECTORY=$2
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

    git worktree add build-"${releases[$release_branch]}" $release_branch

    cp ${LANGUAGE}-config.json build-"${releases[$release_branch]}"

    cd build-"${releases[$release_branch]}"

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0

    cd $TARGET_DIRECTORY && git checkout $release_branch && cd -

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:ID-2fc8126ac8 \
        generate -i ./swagger.json -l ${LANGUAGE} -o generated-${LANGUAGE} \
        -c ./${LANGUAGE}-config.json

    cp -R generated-${LANGUAGE}/* $TARGET_DIRECTORY

    cd $TARGET_DIRECTORY && git add -A . && git commit -a -m "Auto update" \
    && git push origin $release_branch && cd -

    cd ..

    rm -rf build-"${releases[$release_branch]}"

    git worktree prune

done
