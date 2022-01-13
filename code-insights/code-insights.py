import os
import argparse
import requests
import uuid

BITBUCKET_WORKSPACE = os.getenv('BITBUCKET_WORKSPACE')
BITBUCKET_REPO_SLUG = os.getenv('BITBUCKET_REPO_SLUG')
BITBUCKET_COMMIT = os.getenv('BITBUCKET_COMMIT')
BITBUCKET_PIPELINE_UUID = os.getenv('BITBUCKET_PIPELINE_UUID')
BITBUCKET_STEP_UUID = os.getenv('BITBUCKET_STEP_UUID')
PROXIES = {"http": 'http://host.docker.internal:29418'}
DEBUG = os.getenv('DEBUG')

def create_report(title, details, report_type, report_id, reporter, result, data):
    url=f"http://api.bitbucket.org/2.0/repositories/{BITBUCKET_WORKSPACE}/{BITBUCKET_REPO_SLUG}/commit/{BITBUCKET_COMMIT}/reports/{reporter}-{report_id}"
    body = { 
            "title": details,
            "details": title,
            "report_type": report_type,
            "reporter": reporter,
            "link": f"https://bitbucket.org/{BITBUCKET_WORKSPACE}/{BITBUCKET_REPO_SLUG}/addon/pipelines/home#!/results/{BITBUCKET_PIPELINE_UUID}/steps/{BITBUCKET_STEP_UUID}",
            "result": result,
            "data": data
            }
    r = requests.put(url=url, json=body, proxies=PROXIES)
    if not r.ok:
        print(f"Failed to create report {title}")
        print(r.text)

def create_annotation(title, summary, severity, path, line, reporter, report_id, annotation_type, annotation_id):
    url=f"http://api.bitbucket.org/2.0/repositories/{BITBUCKET_WORKSPACE}/{BITBUCKET_REPO_SLUG}/commit/{BITBUCKET_COMMIT}/reports/{reporter}-{report_id}/annotations/{reporter}-{annotation_id}"
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

def read_results_from_file(file):
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

def build_report_data(result):
    report_data = [
            {
                "title": 'Failures',
                "type": 'NUMBER',
                "value": len(result)
                }
            ]

    return report_data

parser = argparse.ArgumentParser(description='Interface with the Bitbucket Code Insights API')
subparsers = parser.add_subparsers(dest="cmd")
create_parser = subparsers.add_parser('create-report')

create_parser.add_argument('title', type=str)
create_parser.add_argument('details', type=str)
create_parser.add_argument('report_type', type=str)
create_parser.add_argument('reporter', type=str)
create_parser.add_argument('file', type=str)

args = parser.parse_args()


if args.cmd == 'create-report':
    print(f"Creating Report")
    results = read_results_from_file(args.file)
    
    create_report(args.title,
            args.details,
            args.report_type,
            str(uuid.uuid4()),
            args.reporter,
            "FAILED" if len(results) else "PASSED",
            build_report_data(results))
