FROM ruby:3.0.1-alpine

MAINTAINER Pavel.Lobashov "shockwavenn@gmail.com"

RUN gem update bundler
COPY . /root/onlyoffice_telegram_bugzilla_notifications
WORKDIR /root/onlyoffice_telegram_bugzilla_notifications
RUN bundle config set without 'development' && \
    bundle install
CMD while :; do rake fetch_news_and_post; sleep 60; done
