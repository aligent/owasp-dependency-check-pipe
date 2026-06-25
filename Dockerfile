FROM owasp/dependency-check:12.2.1

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

# Initialise OWASP DB if UPDATE_DB = true
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

USER 1000

ENTRYPOINT ["/pipe.py"]
