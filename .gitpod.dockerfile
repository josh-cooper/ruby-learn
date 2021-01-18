FROM ruby:2.3-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
# fix for Debian slim. https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      default-jre-headless \
      default-libmysqlclient-dev \
      git \
      imagemagick \
      jq \
      libcurl4-openssl-dev \
      libffi-dev \
      libmagickcore-dev \
      libmagickwand-dev \
      libreadline-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      locales \
      mysql-client \
      python3-setuptools \
      python3-pip \
      zlib1g-dev && \
    apt-get clean && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install pyyaml awscli
# fix for https://bugs.launchpad.net/bugs/1788250
RUN sed -i '/assistive_technologies=org.GNOME.Accessibility.AtkWrapper/s/^/#/g' /etc/java-8-openjdk/accessibility.properties
# set the system locale
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US:en"
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8
RUN bundle config --global github.https true
# for cypress
RUN apt-get update && \
    apt-get install -y \
    xvfb libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2
# Wait For It
RUN curl https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh > /usr/local/bin/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it.sh
# create an unprivileged user
ENV BUNDLE_PATH="/bundle"
RUN useradd -m rails && \
    mkdir /app && \
    mkdir /bundle && \
    chown -R rails:rails -Rv /app /bundle
WORKDIR /app
COPY --chown=rails:rails Gemfile* /app/
COPY --chown=rails:rails local_gems /app/local_gems
RUN bundle install --no-cache -j $(nproc) --retry 5 && \
    rm -rf /bundle/bundler/gems/rails-e17e25cd23e8/.git && \
    rm -rf /bundle/cache/
COPY --chown=rails:rails . .
WORKDIR /app/spec
COPY spec/package.json ./package.json
COPY spec/package-lock.json ./package-lock.json
RUN npm install --quiet
WORKDIR /app
# setup AppVersionFinder
ARG BUILDKITE_BRANCH
ARG BUILDKITE_COMMIT
ARG BUILDKITE_BUILD_URL
ARG BUILDKITE_BUILD_CREATOR
ENV BUILDKITE_BRANCH=$BUILDKITE_BRANCH \
    BUILDKITE_COMMIT=$BUILDKITE_COMMIT \
    BUILDKITE_BUILD_URL=$BUILDKITE_BUILD_URL \
    BUILDKITE_BUILD_CREATOR=$BUILDKITE_BUILD_CREATOR

ENV GEM_HOME=/workspace/.rvm

USER gitpod

CMD echo "Nothing to run"
