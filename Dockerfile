FROM owasp/dependency-check:12.1.0

ARG UPDATE_DB
ARG NVD_API_FEED

USER root
RUN apk add wget bash
RUN cd / && wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

# Install python environment
USER root
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3-dev gcc cargo libressl-dev musl-dev libffi-dev
RUN python3 -m ensurepip

# Install python requirements
USER 1000
COPY requirements.txt /
RUN python3 -m pip install --no-cache-dir -r /requirements.txt

# Initialise OWASP DB if UPDATE_DB = true
# https://github.com/jeremylong/DependencyCheck/blob/2d5fbd9719ddd55a59aea8c234c11e43eaafe26d/Dockerfile#L50
RUN ! ${UPDATE_DB} || /usr/share/dependency-check/bin/dependency-check.sh --updateonly ${NVD_API_FEED:+--nvdDatafeed=${NVD_API_FEED}}

COPY pipe /
USER root
RUN chmod a+x /*.py

USER 1000

ENTRYPOINT ["/pipe.py"]
