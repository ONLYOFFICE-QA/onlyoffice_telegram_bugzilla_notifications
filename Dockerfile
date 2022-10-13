FROM ruby:3.1.2-alpine

MAINTAINER Pavel.Lobashov "shockwavenn@gmail.com"

RUN gem update bundler
COPY . /root/onlyoffice_telegram_bugzilla_notifications
WORKDIR /root/onlyoffice_telegram_bugzilla_notifications
RUN bundle config set without 'development' && \
    bundle install
CMD ["bash", "entrypoint.sh"]
