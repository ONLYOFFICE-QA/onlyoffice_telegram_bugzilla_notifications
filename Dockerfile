FROM ruby:2.5

MAINTAINER Pavel.Lobashov "shockwavenn@gmail.com"

COPY . /root/onlyoffice_telegram_bugzilla_notifications
WORKDIR /root/onlyoffice_telegram_bugzilla_notifications
RUN bundle install --without development
CMD while :; do rake fetch_news_and_post; sleep 60; done
