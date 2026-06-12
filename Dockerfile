FROM owasp/dependency-check:12.2.1

ARG UPDATE_DB
ARG NVD_API_KEY

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
# nvdApiDelay of 700ms prevents 429 rate limit errors from NVD API, where "50 requests in a rolling 30 second window" rule is applied.
RUN ! ${UPDATE_DB} || /usr/share/dependency-check/bin/dependency-check.sh --updateonly ${NVD_API_KEY:+--nvdApiKey=${NVD_API_KEY} --nvdApiDelay=700}

COPY pipe /
USER root
RUN chmod a+x /*.py

USER 1000

ENTRYPOINT ["/pipe.py"]
