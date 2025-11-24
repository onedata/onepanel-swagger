#!/bin/bash
# Authors: Jakub Liput, Bartosz Kryza
# Copyright (C) 2025 Onedata (onedata.org)
# This software is released under the MIT license cited in 'LICENSE.txt'

# Usage: SWAGGER_AGGREGATOR_IMAGE=<image> SWAGGER_BASH_CLIENT_IMAGE=<image> ./generate-bash-packages.sh
# Eg. SWAGGER_AGGREGATOR_IMAGE=docker.onedata.org/swagger-aggregator:1.5.0 SWAGGER_BASH_CLIENT_IMAGE=docker.onedata.org/swagger-codegen:VFS-6328 ./generate-bash-packages.sh
#
# Builds Bash clients for few branches (see the for loop).
# This script should be invoked using `make bash-packages`.

set -e

REPO_NAME=$(basename $(git rev-parse --show-toplevel))
COMPONENT_NAME=$(echo $REPO_NAME | sed 's/-swagger$//g')
LATEST_RELEASE_TAG=$(git describe --abbrev=0 --tags)
CURRENT_BRANCH=$(git branch --show-current)

if [[ -z "$SWAGGER_AGGREGATOR_IMAGE" ]]; then
  echo "You must set SWAGGER_AGGREGATOR_IMAGE env"
  exit 1
fi

if [[ -z "$SWAGGER_BASH_CLIENT_IMAGE" ]]; then
  echo "You must set SWAGGER_BASH_CLIENT_IMAGE env"
  exit 1
fi

for BRANCH in release/${LATEST_RELEASE_TAG} develop; do
  RELEASE_NAME=$(echo $BRANCH | sed 's/^release\///g')
  echo "#################################################"
  echo " Building Bash client release: $RELEASE_NAME"
  echo "#################################################"
  git checkout $BRANCH
  rm -rf generated
  docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_AGGREGATOR_IMAGE}
  docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger:delegated -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json
  BUILD_DIR="packages/bash/$RELEASE_NAME"
  mkdir -p $BUILD_DIR
  cp generated/bash/${COMPONENT_NAME}-rest-cli $BUILD_DIR
  cp generated/bash/_${COMPONENT_NAME}-rest-cli $BUILD_DIR
  cp generated/bash/${COMPONENT_NAME}-rest-cli.bash-completion $BUILD_DIR
done
git checkout $CURRENT_BRANCH