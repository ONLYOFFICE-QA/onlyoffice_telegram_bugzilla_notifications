#!/bin/sh

while :
do
	rake fetch_news_and_post;
	sleep 60;
done
