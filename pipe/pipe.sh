#!/usr/bin/env bash
set -e

source "$(dirname "$0")/common.sh"

run_owasp_checks() {
     OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"
     ${OWASP_PATH} --format=JUNIT --project ${BITBUCKET_REPO_FULL_NAME} --enableExperimental --out ./test-results/ -s ${SCAN_PATH} --failOnCVSS ${CVSS_FAIL_LEVEL}
}

run_owasp_checks

