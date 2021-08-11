# OWASP Dependency Check Pipe

This pipe is used to perform OWASP dependency checks.

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
| SUPPRESSION_FILE_PATH | (Option) Path to a [suppression list](https://jeremylong.github.io/DependencyCheck/general/suppression.html) |
| CVSS_FAIL_LEVEL       | If the score set between 0 and 10 the exit code from dependency-check will indicate if a vulnerability with a CVSS score equal to or higher was identified. |

## Development

The following command can be used to invoke the pipe locally:
Commits published to the `main` branch  will trigger an automated build.

```docker run --env SCAN_PATHS=./composer.json -v $PWD:/build aligent/owasp-depencdency-check-pipe```
