import os
import requests

PROXIES = {"http": 'http://host.docker.internal:29418'}
DEBUG = os.getenv('DEBUG')

class CodeInsights:
    def __init__(self, workspace, repo_slug, commit ):
        self.bitbucket_workspace = workspace
        self.bitbucket_repo_slug = repo_slug
        self.bitbucket_commit = commit

    # Creates a Code Insights report via API
    def create_report(self,title, details, report_type, report_id, reporter, result, link, data):
        url=f"http://api.bitbucket.org/2.0/repositories/{self.bitbucket_workspace}/{self.bitbucket_repo_slug}/commit/{self.bitbucket_commit}/reports/{reporter}-{report_id}"
        body = { 
                "title": title,
                "details": details,
                "report_type": report_type,
                "reporter": reporter,
                "link": link,
                "result": result,
                "data": data
                }
        if DEBUG:
            print(body)
        r = requests.put(url=url, json=body, proxies=PROXIES)
        if not r.ok:
            print(f"Failed to create report {title}")
            print(r.text)

    # Creates a Code Insights annotation via API
    def create_annotation(self, title, summary, severity, path, line, reporter, report_id, annotation_type, annotation_id):
        url=f"http://api.bitbucket.org/2.0/repositories/{self.bitbucket_workspace}/{self.bitbucket_repo_slug}/commit/{self.bitbucket_commit}/reports/{reporter}-{report_id}/annotations/{reporter}-{annotation_id}"
        body = { 
                "title": title,
                "annotation_type": annotation_type,
                "summary": summary,
                "severity": severity,
                "path": path,
                "line": line
                }
        if DEBUG:
            print(body)
        r = requests.put(url=url, json=body, proxies=PROXIES)
        if not r.ok:
            print(f"Failed to create annotation {title}")
            print(r.text)

    # Parses a Junit file and returns all errors
    @staticmethod
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
    @staticmethod
    def build_report_data(failure_count):
        report_data = [
                {
                    "title": 'Failures',
                    "type": 'NUMBER',
                    "value": failure_count
                    }
                ]

        return report_data
