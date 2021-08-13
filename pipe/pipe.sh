#!/usr/bin/env bash
set -e

source "$(dirname "$0")/common.sh"


validate() {
     CVSS_FAIL_LEVEL=${CVSS_FAIL_LEVEL:=1}
     OUTPUT_PATH=${OUTPUT_PATH:='./test-results/'}
}

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"

     if [[ -z "${SUPPRESSION_FILE_PATH}" ]]; then
          ${OWASP_PATH} --format JUNIT --format HTML --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ${OUTPUT_PATH} -s ${SCAN_PATH} --junitFailOnCVSS ${CVSS_FAIL_LEVEL} --failOnCVSS ${CVSS_FAIL_LEVEL}
     else
          ${OWASP_PATH} --format JUNIT --format HTML --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ${OUTPUT_PATH} -s ${SCAN_PATH} --junitFailOnCVSS ${CVSS_FAIL_LEVEL} --failOnCVSS ${CVSS_FAIL_LEVEL} --suppression ${SUPPRESSION_FILE_PATH}
     fi
}

validate
run_owasp_checks

