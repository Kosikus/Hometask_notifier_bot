class EmailNotifierBot
  def initialize
    LoggerService.info("***** Запуск программы *****")

  	@scheduler = Rufus::Scheduler.new
    retries = 0

    begin
      LoggerService.info("Попытка подключения к telegram-боту.")
      @bot = Telegram::Bot::Client.new(AppConfig.tg_bot_token)
      LoggerService.info("Успешно: Подключение к telegram-боту username=#{@bot.api.get_me[:username]}, id=#{@bot.api.get_me[:id]}")
    rescue StandardError => e
      LoggerService.error("Ошибка при подключению к боту.")
      LoggerService.error("Подробности: #{e.message}")
      LoggerService.debug(e.backtrace.join('\n'))

      if retries < AppConfig.max_bot_connection_retries
        retries += 1
        LoggerService.warn("Повторная попытка ##{retries} подключения через #{AppConfig.bot_connection_retry_delay} сек.")
        sleep(AppConfig.bot_connection_retry_delay)
        retry
      else
        LoggerService.fatal("Превышено количество попыток подключения #{AppConfig.max_bot_connection_retries}. Завершение программы.")
        exit(1)
      end
    end

    @imap = MailService.connect
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
  	yesterday = Time.now.in_time_zone(AppConfig.admin_time_zone).yesterday
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
