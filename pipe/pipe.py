#!/usr/bin/env python3

import os
import subprocess
import uuid
import warnings
import logging
from bitbucket import Bitbucket
from bitbucket_pipes_toolkit import Pipe, get_logger

OWASP_PATH="/usr/share/dependency-check/bin/dependency-check.sh"

logger = get_logger()
schema = {
    'SCAN_PATH': {'type': 'string', 'required': True, 'default': '.'},
    'CVSS_FAIL_LEVEL': {'type': 'string', 'required': False, 'default': '1'},
    'SUPPRESSION_FILE_PATH': {'type': 'string', 'required': False, 'default': './suppression.xml'},
    'OUTPUT_PATH': {'type': 'string', 'required': False, 'default': './test-results/'},
    'OSSINDEX_USERNAME': {'type': 'string', 'required': False, 'default': ''},
    'OSSINDEX_PASSWORD': {'type': 'string', 'required': False, 'default': ''},
    'NVD_API_KEY': {'type': 'string', 'required': False, 'default': ''},
    'DISABLE_OSSINDEX': {'type': 'boolean', 'required': False, 'default': False},
    'EXTRA_ARGS': {'type': 'string', 'required': False, 'default': ''},
    }

class OWASPDependencyCheck(Pipe):
    owasp_failure   = False;
    disableOssIndex = False;

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.scan_path              = self.get_variable('SCAN_PATH')
        self.suppression_path       = self.get_variable('SUPPRESSION_FILE_PATH')
        self.ossindexusername       = self.get_variable('OSSINDEX_USERNAME')
        self.ossindexpassword       = self.get_variable('OSSINDEX_PASSWORD')
        self.nvdapikey             = self.get_variable('NVD_API_KEY')
        self.disableOssIndex        = self.get_variable('DISABLE_OSSINDEX')
        self.cvss_fail_level        = self.get_variable('CVSS_FAIL_LEVEL')
        self.out_path               = self.get_variable('OUTPUT_PATH')
        self.bitbucket_repo         = os.getenv('BITBUCKET_REPO_FULL_NAME') if os.getenv('BITBUCKET_REPO_FULL_NAME') else 'Unknown Project'
        self.bitbucket_workspace    = os.getenv('BITBUCKET_WORKSPACE')
        self.bitbucket_repo_slug    = os.getenv('BITBUCKET_REPO_SLUG')
        self.bitbucket_commit       = os.getenv('BITBUCKET_COMMIT')
        self.extra_args             = self.get_variable('EXTRA_ARGS')
        # Not mandatory to set these variables if you run the pipe locally
        try:
            self.bitbucket_pipeline_uuid    = os.getenv('BITBUCKET_PIPELINE_UUID').strip("{}")
            self.bitbucket_step_uuid        = os.getenv('BITBUCKET_STEP_UUID').strip("{}")
        except:
            warnings.warn("Could not find pipeline or step UUIDs", UserWarning)

    # Warning handler function
    def user_warning(message, category, filename, lineno, file=None, line=None):
        print(f"[WARN] {category.__name__}: {message} at {filename}:{lineno}")

    warnings.showwarning = user_warning

    def run_owasp_check(self):

        owasp_command = [OWASP_PATH,
                '--format', 'JUNIT',
                '--format', 'HTML',
                '--prettyPrint',
                '--project', self.bitbucket_repo,
                '--enableExperimental',
                '--out', self.out_path,
                '-s', self.scan_path,
                '--junitFailOnCVSS', self.cvss_fail_level,
                '--failOnCVSS', self.cvss_fail_level]
        if self.suppression_path and os.path.exists(self.suppression_path):
            owasp_command.append('--suppression')
            owasp_command.append(self.suppression_path)

        if self.ossindexusername and self.ossindexpassword:
            owasp_command.append('--ossIndexUsername')
            owasp_command.append(self.ossindexusername)
            owasp_command.append('--ossIndexPassword')
            owasp_command.append(self.ossindexpassword)

        if self.nvdapikey:
            owasp_command.append('--nvdApiKey')
            owasp_command.append(self.nvdapikey)

        if self.disableOssIndex == True:
            owasp_command.append('--disableOssIndex')

        if self.extra_args:
            owasp_command.extend(self.extra_args.split())

        logging.info(f"Running OWASP dependency check with command: {owasp_command}")

        # Run the OWASP dependency check
        owasp = subprocess.run(owasp_command,
                universal_newlines=True)

        self.owasp_failure = bool(owasp.returncode)


    def upload_report(self):

        # Parses a Junit file and returns all errors
        def read_failures_from_file(file):
            from junitparser import JUnitXml

            results = []
            xml = JUnitXml.fromfile(file)
            if not xml.failures: return []
            for suite in xml:
                # handle suites
                if suite.failures == 0: continue
                for case in suite:
                    results.append(case.result)

            return results

        # Builds a report given a number of failures
        def build_report_data(failure_count):
            report_data = [
                    {
                        "title": 'Failures',
                        "type": 'NUMBER',
                        "value": failure_count
                        }
                    ]

            return report_data

        report_id = str(uuid.uuid4())

        if self.bitbucket_repo != 'Unknown Project':
            bitbucket_api = Bitbucket(
                proxies={"http": 'http://host.docker.internal:29418'},
                protocol="http"
            )


            failures = read_failures_from_file(
                    f"{self.out_path}dependency-check-junit.xml"
                    )

            bitbucket_api.create_report(
                    "OWASP Dependency Scan",
                    "Results produced when scanning {self.scan_path} for known OWASP vulnerabilities." ,
                    "SECURITY" ,
                    report_id,
                    "owasp-dependency-check-pipe" ,
                    "FAILED" if len(failures) else "PASSED",
                    f"https://bitbucket.org/{self.bitbucket_workspace}/{self.bitbucket_repo_slug}/addon/pipelines/home#!/results/{self.bitbucket_pipeline_uuid}/steps/{self.bitbucket_step_uuid}/test-report",
                    build_report_data(len(failures)),
                    self.bitbucket_workspace,
                    self.bitbucket_repo_slug,
                    self.bitbucket_commit
                    )


    def run(self):
        super().run()
        self.run_owasp_check()
        self.upload_report()
        if self.owasp_failure:
            self.fail(message=f"Failed OWASP dependency scan")
        else:
            self.success(message=f"Passed OWASP dependency scan")


if __name__ == '__main__':
    pipe = OWASPDependencyCheck(schema=schema, logger=logger)
    pipe.run()
