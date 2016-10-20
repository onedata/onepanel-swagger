#!/usr/bin/env bats


export ONEPANEL_HOST="https://localhost:9443"
export ONEPANEL_BASIC_AUTH="alice:secret"

export ONEPANEL_CLI=generated/bash/onepanel-rest-cli

#
# Tests generation of curl requests
#
@test "addUser json generation" {
    run bash $ONEPANEL_CLI onepanel-rest-cli addUser username:=bob password:=secret userRole:=regular --dry-run
    [[ "$output" =~ "${ONEPROVIDER_HOST}/api/v3/onepanel/users" ]]
    [[ "$output" =~ "-X POST" ]]
    [[ "$output" =~ "-u alice:secret" ]]
    [[ "$output" =~ "\"username\": \"bob\"" ]]
    [[ "$output" =~ "\"password\": \"secret\"" ]]
}



