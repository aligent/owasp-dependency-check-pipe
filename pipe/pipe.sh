#!/usr/bin/env bash
#
set -e

source "$(dirname "$0")/common.sh"

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"
     REPORT_PATH=/var/tmp/dependency-check-report.html

     ${OWASP_PATH} --prettyPrint --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out /test-results/ -s ${SCAN_PATH}
}

run_owasp_checks

