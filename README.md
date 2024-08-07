# onlyoffice_telegram_bugzilla_notifications

Git bot for sending notification about bugzilla new bugs

## Config

The `config.yml` file must have the following structure:

```yaml
chat1:
  telegram_bot_token: token
  channel_id: id-of-channel
  products: ['product_name']
  
chat2:
  telegram_bot_token: token
  channel_id: id-of-channel

common_config:
  bugzilla_url: bugzilla_url
  bugzilla_key: bugzilla_key
  check_period: 60 # Timeout between checks for new bug
```

## Parameter Descriptions

### Chats

Each chat should be defined with a unique name (chat1, chat2, etc.)
and contain the following parameters:

- `telegram_bot_token` (string, required): Token for accessing the Telegram bot.
- `channel_id` (string, required): ID of the channel where messages will be sent.
- `products` (array, optional): List of products associated with this chat.
Used for filtering bugs.

### Common Parameters

- `bugzilla_url` (string, required): - The URL of your Bugzilla server.
- `bugzilla_key` (string, required): - The API key for accessing Bugzilla.
- `check_period` (integer, optional): - Timeout between checks for new bug.
By Default 60 seconds.

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
