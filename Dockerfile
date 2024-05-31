FROM ruby:3.3.2-alpine

LABEL maintainer="Pavel.Lobashov <shockwavenn@gmail.com>"

RUN apk --no-cache add gcc \
                   make \
                   musl-dev && \
    gem update bundler
COPY . /root/onlyoffice_telegram_bugzilla_notifications
WORKDIR /root/onlyoffice_telegram_bugzilla_notifications
RUN bundle config set without 'development' && \
    bundle install
CMD ["sh", "entrypoint.sh"]
