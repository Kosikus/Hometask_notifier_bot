class EmailNotifierBot
  def initialize
  	@scheduler = Rufus::Scheduler.new
  	@bot = Telegram::Bot::Client.new(AppConfig.tg_bot_token)
  	@imap = MailService.connect

    puts "Бот запущен #{Time}"
  end

  def run
  	LoggerService.info('Запуск бота')

  	@scheduler.every AppConfig.sent_email_check_interval do
  	  check_mail
  	end

  	@bot.listen do |message|
  	  handle_bot_commands(message)
  	end

  	@imap.logout
  	@imap.disconnect
  end

  def check_mail
  	yesterday = AppConfig.admin_time_zone.local(Time.now.year, Time.now.month, Time.now.day).yesterday
  	mails = MailService.fetch_messages(@imap, yesterday)
  	users = UserManager.load_users(USERS_DATA_FILE_PATH)

  	NotificationService.send_notifications(@bot, users, mails)
  end

  def handle_bot_commands(message)
    case message
  	when '/start'
      @bot.api.sendmessage(chat_id: message.chat_id, text: "Привет! Я бот, который уведомит тебя о новых письмах.")
    when '/say_hello'
      @bot.api.sendmessage(chat_id: message.chat_id, text: "Привет, #{message.from.first_name}!")
    else
      @bot.api.sendmessage(chat_id: message.chat_id, text: "Неизвестная команда")
    end
  end
end