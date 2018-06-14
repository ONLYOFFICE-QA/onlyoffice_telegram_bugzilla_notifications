# onlyoffice_telegram_bugzilla_notifications
Git bot for sending notification about bugzilla new bugs

# Config
By file `config.yml` with data
```
telegram_bot_token: token
channel_id: id-of-channel
bugzilla_url: bugzilla_url
bugzilla_key: bugzilla_key
```

Last send bug set by
`echo '37910' > last_send_bug.info`

# Docker compose

```
docker-compose up -d
```

# How to update

```
git pull --prune
docker-compose up -d --no-deps --build app
```