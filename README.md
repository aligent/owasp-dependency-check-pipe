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
                SCAN_PATHS: "./composer.json"
                EXPERIMENTAL: "TRUE"
```
## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| SCAN_PATHS            | Comma separated list of relative paths to scan |
| EXPERIMENTAL          | (Optional) Enable OWASP dependency check experimental features |

## Development

The following command can be used to invoke the pipe locally:
Commits published to the `main` branch  will trigger an automated build.

```docker run --env SCAN_PATHS=./composer.json -v $PWD:/build aligent/owasp-depencdency-check-pipe```
