#!/bin/bash

DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]:-$0}))"
cd "${DIR}"

source ../extended-builtins.sh

import-ns ../helpers.sh helpers

set -- "arg1=1" "--arg2=2" "-arg3=3" "-"

helpers.parse-arguments "$@"
helpers.require-arguments arg1 arg2 arg3 arg4

helpers.ascii-date
