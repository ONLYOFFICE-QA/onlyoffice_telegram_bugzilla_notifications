# onlyoffice_telegram_bugzilla_notifications

Git bot for sending notification about bugzilla new bugs

## Config

By file `config.yml` with data

```yaml
telegram_bot_token: token
channel_id: id-of-channel
bugzilla_url: bugzilla_url
bugzilla_key: bugzilla_key
```

Last send bug set by
`echo '37910' > last_send_bug.info`

## Docker compose

```shell script
docker-compose up -d
```

## How to update

```shell script
git pull --prune
docker compose down
docker compose pull
docker compose up -d
```
