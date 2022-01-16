FROM owasp/dependency-check

USER root 
COPY pipe /
RUN apk add wget bash
RUN cd / && wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh
RUN chmod a+x /*.sh

# Initialise OWASP DB
# https://github.com/jeremylong/DependencyCheck/blob/2d5fbd9719ddd55a59aea8c234c11e43eaafe26d/Dockerfile#L50
USER 1000
RUN /usr/share/dependency-check/bin/dependency-check.sh --updateonly

# Install python environment
USER root 
COPY ./code-insights /usr/bin/code-insights
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools junitparser requests

USER 1000
ENTRYPOINT ["/pipe.sh"]
