# OWASP Dependency Check Pipe

This pipe is used to perform OWASP dependency checks using [jeremylong/DependencyCheck](https://github.com/jeremylong/DependencyCheck)

## YAML Definition

Add the following your `bitbucket-pipelines.yml` file:

```yaml
      - step:
          name: "Code Standards check"
          script:
            - pipe: docker:aligent/owasp-dependency-check-pipe
              variables:
                SCAN_PATH: "./composer.lock"
                CVSS_FAIL_LEVEL: "1"
```
## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| SCAN_PATH             | Relative paths to scan. i.e composer.lock, package-lock.json |
| CVSS_FAIL_LEVEL       | (Optional) If the score set between 0 and 10 the exit code from dependency-check will indicate if a vulnerability with a CVSS score equal to or higher was identified. |
| SUPPRESSION_FILE_PATH | (Optional) Path to a [suppression list](https://jeremylong.github.io/DependencyCheck/general/suppression.html) |
| OUTPUT_PATH           | (Optional) Path to output test results. |

## Development

The following command with world-writable `test-results` directory under project root can be used to invoke the pipe locally:

```
docker run -e CVSS_FAIL_LEVEL=1 -e BITBUCKET_REPO_FULL_NAME=test -e SCAN_PATH=./composer.lock -v $PWD:/build --workdir=/build aligent/owasp-dependency-check-pipe
```

Commits published to the `main` branch  will trigger an automated build.
