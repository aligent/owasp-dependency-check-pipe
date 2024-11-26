FROM owasp/dependency-check

ARG NVD_API_KEY
ARG OSSINDEX_USERNAME
ARG OSSINDEX_PASSWORD
ARG UPDATE_DB

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
RUN ! ${UPDATE_DB} || /usr/share/dependency-check/bin/dependency-check.sh --updateonly --nvdApiKey ${NVD_API_KEY} --ossIndexUsername ${OSSINDEX_USERNAME} --ossIndexPassword ${OSSINDEX_PASSWORD} --nvdMaxRetryCount 20 --nvdApiDelay ${NVD_API_DELAY}

COPY pipe /
USER root
RUN chmod a+x /*.py

USER 1000
ENTRYPOINT ["/pipe.py"]
