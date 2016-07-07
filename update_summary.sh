#!/bin/bash

function update_summary {
  SUMMARY=$1
  SP="SWAGGER_INCLUDE_START" # start prefix
  EP="SWAGGER_INCLUDE_END" # end prefix
  TO_INSERT=$3

  START="$SP $2"
  END="$EP $2"
  sed -i -e "/$START/,/$END/ {" -e '//!d' -e "/$START/r $TO_INSERT" -e '}' $SUMMARY
}
#update_summary $1 $2 $3



