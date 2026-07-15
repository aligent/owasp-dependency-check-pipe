# ---- Stage 1: delta-update the NVD database on top of the previous build ----
# Self-referential: pulls previous build which contains recent NVD database.
# Delta updates are fast (<7 days). Schedule builds every few days to stay fresh.
# Bootstrap: first build requires full DB download (~4-10 hours).
FROM aligent/owasp-dependency-check-pipe:latest AS previous

ARG UPDATE_DB

USER root
RUN apk add wget bash
RUN cd / && wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

# Install python environment
USER root
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 py3-pip python3-dev gcc cargo libressl-dev musl-dev libffi-dev

# Install python requirements
USER 1000
COPY requirements.txt /
RUN python3 -m pip install --no-cache-dir --break-system-packages -r /requirements.txt

# Run delta update if UPDATE_DB = true (fetches only new CVEs since base image was built).
# nvdApiDelay of 1000ms and nvdApiResultsPerPage of 1000 prevent 429 rate limit errors from NVD API.
# NVD_API_KEY is passed as a BuildKit secret to avoid exposing it in build logs.
# mode=0444 is required because BuildKit secrets default to root-only (0400), but this runs as USER 1000.
RUN --mount=type=secret,id=NVD_API_KEY,mode=0444 \
    NVD_KEY=$(cat /run/secrets/NVD_API_KEY 2>/dev/null || echo "") && \
    ! ${UPDATE_DB} || /usr/share/dependency-check/bin/dependency-check.sh --updateonly \
    ${NVD_KEY:+--nvdApiKey=${NVD_KEY}} --nvdApiDelay=1000 --nvdApiResultsPerPage=1000

COPY pipe /
USER root
RUN chmod a+x /*.py

# ---- Stage 2: flatten into a single layer to reset the FROM-chain depth ----
# The self-referential FROM above grows the overlay layer chain on every build.
# Without this, the chain eventually exceeds Docker's 128-layer limit and the
# export/import step fails with "max depth exceeded". Copying the whole rootfs
# from the previous stage into a scratch base collapses it back to one layer.
# COPY does not carry image metadata, so the config below is restated verbatim
# from the base image (verified against `docker inspect`); the inherited dotnet
# runtime vars are kept because the .NET assembly analyzer relies on them.
FROM scratch
COPY --from=previous / /

ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    JAVA_HOME="/opt/jdk" \
    JAVA_OPTS="-Danalyzer.assembly.dotnet.path=/usr/bin/dotnet -Danalyzer.bundle.audit.path=/usr/bin/bundle-audit -Danalyzer.golang.path=/usr/local/go/bin/go" \
    ODC_NAME="dependency-check-docker" \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true \
    DOTNET_VERSION=8.0.25 \
    PYTHONUNBUFFERED=1 \
    user="dependencycheck"

VOLUME ["/report", "/src"]
WORKDIR /src
USER 1000

ENTRYPOINT ["/pipe.py"]
