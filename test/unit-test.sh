#!/bin/bash

DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]:-$0}))"
cd "${DIR}"

source ../extended-builtins.sh

import-ns ../helpers.sh helpers

function assert_equal() {
  if [[ "${1}" != "${2}" ]]; then
    echo "expected '${1}' to equal '${2}'"
    exit 23
  fi
}


set -- "arg1=1" "--arg2=2" "-arg3=3" "-arg4=a1 a2 a3 a4"

helpers.parse-arguments "$@"
helpers.require-arguments arg1 arg2 arg3 arg4

set -- "arg1=1" "--arg2=2" "-arg3=3" "-arg4=a1 a2 a3 a4"

helpers.parse-arguments "$@"
helpers.require-arguments arg1 arg2 arg3 arg4

unix_ts='1421314070'
ascii_ts='2015-01-15 10:27:50'
ascii_date='2015-01-15'
ascii_time='10:27:50'
ascii_ts_2='2015-01-14 11:27:50'

assert_equal "$(helpers.ascii-ts --date=@${unix_ts})" "$ascii_ts"
assert_equal "$(helpers.ascii-to-unix ${ascii_ts})" "$unix_ts"
assert_equal "$(helpers.unix-to-ascii $unix_ts)" "$ascii_ts"
assert_equal "$(helpers.ascii-date --date=@${unix_ts})" "$ascii_date"
assert_equal "$(helpers.ascii-time --date=@${unix_ts})" "$ascii_time"
assert_equal "$(helpers.is-ascii-date $ascii_date && echo 1)" "1"
assert_equal "$(helpers.is-ascii-time $ascii_time && echo 1)" "1"
assert_equal "$(helpers.is-ascii-ts $ascii_ts && echo 1)" "1"
