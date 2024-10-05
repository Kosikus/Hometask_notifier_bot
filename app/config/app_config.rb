class AppConfig
	# интервал проверки почты на почтовом сервисе
  def self.sent_email_check_interval
    ENV['SENT_EMAIL_CHECK_INTERVAL']
  end

  # максимальное количество символов в сообщении бота
  def self.bot_message_character_limit
    ENV['BOT_MESSAGE_CHARACTER_LIMIT'].to_i
  end

  # путь к файлу для логирования
	def self.log_file_path
    ENV['LOG_FILE_PATH']
  end

	# telegram_токен бота 
	def self.tg_bot_token
		ENV['TG_BOT_TOKEN']
	end

	# telegram id админа (для отправки копий оповещений)
	def self.admin_tg_id
		ENV['ADMIN_TG_ID']
	end

  # хост imap-почтового сервера
	def self.imap_host
    ENV['IMAP_HOST']
  end

  # номер порта imap-почтового сервера
	def self.imap_port
    ENV['IMAP_PORT']
  end
  
	# имя почтового ящика
	def self.email_user_name
		ENV['EMAIL_USER_NAME']
	end
 
  # пароль к почтовому сервису
	def self.email_password
		ENV['EMAIL_PASSWORD']
	end

  # наименование папки с отправленными письма на почт. сервисе
	def self.email_sent_folder
		ENV['EMAIL_SENT_FOLDER']
	end

  # адрес к файлу с данными пользователей
	def self.json_file_path
		ENV['JSON_FILE_PATH']
	end

  # временная зона администратора (базовая)
  def self.admin_time_zone
	  ENV['TZ']
	end

  # количество попыток подключения к тг-боту
	def self.max_bot_connection_retries
    ENV['MAX_BOT_CONNECTION_RETRIES'].to_i
	end

  # задержка (сек) между попытками подключения к тг-боту
	def self.bot_connection_retry_delay
		ENV['BOT_CONNECTION_RETRY_DELAY'].to_i
	end

  # количество попыток подключения к почт. сервису
	def self.max_imap_connection_retries
    ENV['MAX_IMAP_CONNECTION_RETRIES'].to_i
	end

  # задержка (сек) между попытками подключения к почт. сервису
	def self.imap_connection_retry_delay
		ENV['IMAP_CONNECTION_RETRY_DELAY'].to_i
	end
end
