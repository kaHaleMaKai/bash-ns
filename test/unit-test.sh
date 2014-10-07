#!/bin/bash
source ../extended-builtins.sh

alerts_address='adition-pa-alerts@performance-media.de'
addresses="lars.winderling@performance-advertising, rw@performance-media.de, ${alerts_address}"
header="From: ${alerts_address}"
subject='Adition tagging alert'
footer="This message has been automatically generated to inform you about the adition tagging being slow."

import-ns ../helpers.sh helpers

helpers.parse-arguments $@
helpers.require-argument last_alert
helpers.require-argument log
helpers.require-argument max_fails
helpers.require-argument timeout
helpers.require-argument interval
helpers.require-argument nr_of_runs

helpers.check-for-absent-arguments

