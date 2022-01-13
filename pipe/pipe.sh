#!/usr/bin/env bash
set -e

source "$(dirname "$0")/common.sh"


validate() {
     CVSS_FAIL_LEVEL=${CVSS_FAIL_LEVEL:=1}
     OUTPUT_PATH=${OUTPUT_PATH:='./test-results/'}
}

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"

     # Capture the exist code from run_owasp_checks.
     # Even if this fails we still want to generate the report.

     if [[ -z "${SUPPRESSION_FILE_PATH}" ]]; then
          ${OWASP_PATH} --format JUNIT --format HTML --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ${OUTPUT_PATH} -s ${SCAN_PATH} --junitFailOnCVSS ${CVSS_FAIL_LEVEL} --failOnCVSS ${CVSS_FAIL_LEVEL} || EXIT_CODE=$?
     else
          ${OWASP_PATH} --format JUNIT --format HTML --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ${OUTPUT_PATH} -s ${SCAN_PATH} --junitFailOnCVSS ${CVSS_FAIL_LEVEL} --failOnCVSS ${CVSS_FAIL_LEVEL} --suppression ${SUPPRESSION_FILE_PATH} || EXIT_CODE=$?
     fi

}

upload_report() {
     python3 /usr/bin/code-insights/code-insights.py junit-report "OWASP Dependency Scan" "Results produced when scanning ${SCAN_PATH} known OWASP vulnerabilities." "SECURITY" "owasp-dependency-check-pipe" ${OUTPUT_PATH}dependency-check-junit.xml $SCAN_PATH
}

validate
run_owasp_checks
upload_report
# Return the exit code from run_owasp_checks
exit $EXIT_CODE
