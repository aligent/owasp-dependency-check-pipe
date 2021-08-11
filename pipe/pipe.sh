#!/usr/bin/env bash
set -e

source "$(dirname "$0")/common.sh"


validate() {
     CVSS_FAIL_LEVEL=${CVSS_FAIL_LEVEL:=false}
}

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"

     if [[ -z "${SUPPRESSION_FILE_PATH}" ]]; then
          ${OWASP_PATH} --format=JUNIT --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ./test-results/ -s ${SCAN_PATH} --failOnCVSS ${CVSS_FAIL_LEVEL}
     else
          ${OWASP_PATH} --format=JUNIT --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ./test-results/ -s ${SCAN_PATH} --failOnCVSS ${CVSS_FAIL_LEVEL} --suppression ${SUPPRESSION_FILE_PATH}
     fi

}

run_owasp_checks

