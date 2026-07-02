# OWASP Dependency Check Pipe

This pipe is used to perform OWASP dependency checks using [jeremylong/DependencyCheck](https://github.com/jeremylong/DependencyCheck)

## YAML Definition

Add the following your `bitbucket-pipelines.yml` file:

```yaml
      - step:
          name: "Code Standards check"
          script:
            - pipe: docker://aligent/owasp-dependency-check-pipe
              variables:
                SCAN_PATH: "./composer.lock"
                CVSS_FAIL_LEVEL: "1"
```

## Variables

| Variable              | Usage                                                       |
| --------------------- | ----------------------------------------------------------- |
| SCAN_PATH             | Relative paths to scan. Default: repository root. |
| CVSS_FAIL_LEVEL       | (Optional) If the score set between 0 and 10 the exit code from dependency-check will indicate if a vulnerability with a CVSS score equal to or higher was identified. |
| SUPPRESSION_FILE_PATH | (Optional) Path to a [suppression list](https://jeremylong.github.io/DependencyCheck/general/suppression.html) |
| DISABLE_OSSINDEX      | (Optional) Disable OSS Index Analysis. Boolean. Default: true |
| OSSINDEX_USERNAME      | (Optional) Provide OSS Index Username. Disregarded when DISABLE_OSSINDEX is set True |
| OSSINDEX_PASSWORD      | (Optional) Provide OSS Index Password. Disregarded when DISABLE_OSSINDEX is set True |
| NVD_API_KEY          | (Optional) Provide an API key for NVD. |
| OUTPUT_PATH           | (Optional) Path to output test results. |
| UPDATE_DB             | (Optional) Pass `true` if that database should be updated. Defaults to false |
| EXTRA_ARGS            | (Optional) Extra arguments to pass to dependency-check. i.e `--disableRetireJS` |

⚠️ For npm/yarn projects, you should provide the directory containing `package-lock.json` or `yarn.lock` and `node-modules` as `SCAN_PATH`.

## Development

The following command with world-writable `test-results` directory under project root can be used to invoke the pipe locally:

```bash
docker run --rm -e OUTPUT_PATH="/tmp/test-results/" -e CVSS_FAIL_LEVEL=1 -e SCAN_PATH=./composer.lock -v $PWD:/build --workdir=/build aligent/owasp-dependency-check-pipe
```

## CI/CD

Docker images are built and pushed to Docker Hub via GitHub Actions. The workflow:

- Triggers on pushes to `main` branch
- Runs weekly (Sundays at 2am UTC) to update the NVD database
- Can be manually triggered with optional cache bypass

### Required Secrets

Configure the following secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `NVD_API_KEY` | NVD API key for faster database updates |

### Caching

The workflow uses GitHub Actions cache to store Docker build layers, significantly reducing build times for subsequent builds. The NVD database layer is cached and reused unless:

- The scheduled weekly rebuild runs (forces fresh database download)
- Manual trigger with "Force NVD database update" option enabled
