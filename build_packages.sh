#!/usr/bin/env bash

declare -A releases

#
# Maps branch names to release names
#
releases["release/3.0.0-rc9"]="3.0.0-rc9"
releases["release/3.0.0-rc10"]="3.0.0-rc10"
releases["release/3.0.0-rc11"]="3.0.0-rc11"
releases["release/3.0.0-rc12"]="3.0.0-rc12"

rm -rf packages
for release_branch in "${!releases[@]}"; do
    git checkout $release_branch
    rm -rf generated

    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger docker.onedata.org/swagger-aggregator:1.5.0
    docker run --rm -e "CHOWNUID=${UID}" \
        -v `pwd`:/swagger -t docker.onedata.org/bash-swagger-codegen:0.3.8 generate \
        -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

    mkdir -p "packages/bash/${releases[$release_branch]}"
    cp generated/bash/onepanel-rest-cli \
        "packages/bash/${releases[$release_branch]}/"
    cp generated/bash/_onepanel-rest-cli \
        "packages/bash/${releases[$release_branch]}/"
    cp generated/bash/onepanel-rest-cli.bash-completion \
        "packages/bash/${releases[$release_branch]}/"
done

git checkout master
