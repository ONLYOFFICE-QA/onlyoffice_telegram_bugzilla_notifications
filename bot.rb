config = YAML.load_file('config.yml')

Telegram::Bot::Client.run(config['telegram_bot_token']) do |bot|
  bot.api.sendMessage(chat_id: config['channel_id'], text: 'Hello')
end
