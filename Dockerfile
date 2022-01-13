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

# Install python/pip
USER root 
COPY ./code-insights /usr/bin/code-insights
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip3 install pipenv
RUN python3 --version
RUN chown 1000 /usr/bin/code-insights

# Install python code-insight dependencies 
USER 1000
RUN cd /usr/bin/code-insights && pipenv install
RUN cd /usr/bin/code-insights && pipenv run code-insights


ENTRYPOINT ["/pipe.sh"]
