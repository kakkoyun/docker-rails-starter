FROM ruby:2.4-alpine

# NOTICE: Alpine can cause locale problem, concerning PostgreSQL
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN apk update && apk --update add \
  curl \
  git \
  gnupg \
  imagemagick \
  make \
  nginx \
  postgresql-client \
  tzdata \
  && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
  curl -o /usr/local/bin/gosu -fsSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" && \
  curl -o /usr/local/bin/gosu.asc -fsSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64.asc" && \
  gpg --verify /usr/local/bin/gosu.asc && \
  rm /usr/local/bin/gosu.asc && \
  rm -rf /root/.gnupg/ && \
  chmod +x /usr/local/bin/gosu

ENV RAILS_ROOT=/docker-rails-starter/current RAILS_ENV=production RACK_ENV=production

RUN rm -rf /etc/nginx/conf.d/example_ssl.conf && \
  rm -rf /etc/nginx/conf.d/default.conf && \
  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log && \
  mkdir -p $RAILS_ROOT/tmp/pids && \
  mkdir -p $RAILS_ROOT/public

COPY Gemfile* /tmp/
WORKDIR /tmp

# May be missing: openssl-dev libc-dev linux-headers
RUN apk --update add --no-cache --virtual build-dependencies \
  build-base postgresql-dev && \
  gem install bundler && \
  bundle config --global disable_shared_gems 0 && \
  bundle config --global frozen 1 && \
  bundle config --global git.allow_insecure true && \
  bundle install --jobs $(grep -c ^processor /proc/cpuinfo 2>/dev/null || 4) \
    --without development test \
  && \
  apk del build-dependencies

ADD . $RAILS_ROOT/
WORKDIR $RAILS_ROOT/

RUN apk --update add --no-cache --virtual asset-precompile-dependencies \
  nodejs && \
  bundle exec rake assets:precompile assets:clean && \
  apk del asset-precompile-dependencies

COPY container/files/etc/profile /service/etc/profile
COPY container/files/nginx/nginx.conf /etc/nginx/nginx.conf
COPY container/files/nginx/starter.conf /etc/nginx/conf.d/starter.conf
COPY container/files/puma/puma.rb config/puma.rb

RUN bundle exec rake tmp:clear

EXPOSE 3000
EXPOSE 80

ENTRYPOINT ["./container/launch.sh"]
CMD foreman start -f Procfile

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_REF_MSG
ARG RELEASE_NOTES
ARG VCS_URL
ARG VERSION

LABEL vendor="kakkoyun" \
      name="kakkoyun/docker-rails-starter" \
      maintainer="kakkoyun@gmail.com" \
      com.kakkoyun.component.name="docker-rails-starter" \
      com.kakkoyun.component.build-date="$BUILD_DATE" \
      com.kakkoyun.component.vcs-url="$VCS_URL" \
      com.kakkoyun.component.vcs-ref="$VCS_REF" \
      com.kakkoyun.component.vcs-ref-msg="$VCS_REF_MSG" \
      com.kakkoyun.component.version="$VERSION" \
      com.kakkoyun.component.distribution-scope="private" \
      com.kakkoyun.component.url="https://github.com/kakkoyun/docker-rails-starter" \
      com.kakkoyun.component.run="docker run -e ENV_NAME=ENV_VALUE IMAGE" \
      com.kakkoyun.component.environment.required="" \
      com.kakkoyun.component.environment.optional="" \
      com.kakkoyun.component.dockerfile="/docker-rails-starter/current/Dockerfile"
