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
releases["develop"]="3.0.0-dev"
releases["release/future"]="3.0.0-dev"

# Checkout the client repository which should be updated
git clone \
    ssh://git@git.plgrid.pl:7999/vfs/${SERVICE}-${LANGUAGE}-client.git \
    ${TARGET_DIRECTORY}

rm -rf packages

for release_branch in "${!releases[@]}"; do

    # Checkout the specific API version as worktree subdirectory
    git worktree add build-"${releases[$release_branch]}" remotes/origin/$release_branch

    # Copy the codegen config file to workdir and set version
    cp ${LANGUAGE}-config.json build-"${releases[$release_branch]}"/
    sed -i "s/__PACKAGE_VERSION__/${releases[$release_branch]}/g" \
        build-"${releases[$release_branch]}"/${LANGUAGE}-config.json

    cd build-"${releases[$release_branch]}"

    # Generate a combined swagger.json from yaml files
    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0

    # Enter the generated client directory
    cd $TARGET_DIRECTORY && \
    git checkout $release_branch || git checkout -b $release_branch && \
    cd -

    # Build the javascript client from the current API version in the worktree
    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger -t docker.onedata.org/swagger-codegen:2.2.2-1b1767e \
        generate -i ./swagger.json -l ${LANGUAGE} -o ./generated-${LANGUAGE}/ \
        -c ./${LANGUAGE}-config.json

    # Copy the generated javascript code to the client repository working dir
    cp -R generated-${LANGUAGE}/* $TARGET_DIRECTORY

    # Commit&push the changes to the client repository
    cd $TARGET_DIRECTORY
    git add -A . && \
    git commit -a -m "Auto update" \
    && git push origin $release_branch
    cd -

    cd ..

    # Cleanup
    rm -rf build-"${releases[$release_branch]}"
    git worktree prune

done

rm -rf ${TARGET_DIRECTORY}
