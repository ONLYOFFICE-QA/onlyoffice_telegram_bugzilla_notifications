# onlyoffice_telegram_bugzilla_notifications

Git bot for sending notification about bugzilla new bugs

## Config

By file `config.yml` with data

```yaml
telegram_bot_token: token
channel_id: id-of-channel
bugzilla_url: bugzilla_url
bugzilla_key: bugzilla_key
check_period: 60 # Timeout between checks for new bug
products: ['product_name']
```

Last send bug set by
`echo '37910' > last_send_bug.info`

`telegram_bot_token` - telegram_bot_token: Your Telegram bot token,
which you can obtain by creating a bot through BotFather on Telegram.(Required)

`channel_id` - The ID of the Telegram channel where the bot will
send notifications about new bugs.(Required)

`bugzilla_url` - The URL of your Bugzilla server.(Required)

`bugzilla_key` - The API key for accessing Bugzilla.(Required)

`check_period` - Timeout between checks for new bug.
By Default 60 seconds.(Optional)

`products` - Array with product names for sending
messages with selection by product name.(Optional)

## DocSpace App Config

For the docspace application, create the `docspace_config.yml`
file with the 'DocSpace' product selection

Last send bug set by
`echo '37910' > last_send_bug_docspace.info`

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
