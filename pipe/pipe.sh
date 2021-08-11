#!/usr/bin/env bash

source "$(dirname "$0")/common.sh"

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"
     ${OWASP_PATH} --format=JSON --prettyPrint --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ./test-results/ -s ${SCAN_PATH} --failOnCVSS ${CVSS_FAIL_LEVEL}

     RESULT=$?
     echo "Result:"
     echo $RESULT
     if [ $RESULT -ne 0 ]; then
          fail "Build did not pass OWASP security checks. Please see test output."
     fi

}

run_owasp_checks

