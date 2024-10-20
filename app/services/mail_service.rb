class MailService
  def self.connect
    retries = 0

    begin  
      if retries < AppConfig.max_imap_connection_retries && retries != 0
        LoggerService.warn("Повторная попытка ##{retries} подключения через #{AppConfig.imap_connection_retry_delay} сек.")
        sleep(AppConfig.imap_connection_retry_delay)
      elsif retries >= AppConfig.max_imap_connection_retries
        LoggerService.fatal("Превышено количество попыток подключения #{AppConfig.max_imap_connection_retries}. Завершение программы.")
        exit(1)
      end

      LoggerService.info("Попытка подключения к IMAP-серверу \"#{AppConfig.imap_host}\" на порту \"#{AppConfig.imap_port}\"")
      imap = Net::IMAP.new(AppConfig.imap_host, port: AppConfig.imap_port, ssl: true)
      LoggerService.info("Успешно: подключение к IMAP-серверу \"#{AppConfig.imap_host}\"")

      imap.login(AppConfig.email_user_name, AppConfig.email_password)
      LoggerService.info("Успешно: Аутентификация пользователя \"#{AppConfig.email_user_name}\"")

      imap

    rescue Net::IMAP::NoResponseError => e
      LoggerService.error("Ошибка аутентификации на IMAP-сервере: \"#{e.message}\"")

      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue SocketError => e
      LoggerService.error("Нет подключения к сети или неверно указан хост. Не удалось подключиться к IMAP-серверу \"#{AppConfig.imap_host}\": #{e.message}")

      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue Net::IMAP::ByeResponseError => e

      LoggerService.error("IMAP-сервер неожиданно разорвал соединение: \"#{e.message}\"")

      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue => e

      LoggerService.error("Неизвестная ошибка при подключении к серверу: \"#{e.message}\"")

      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    end
  end

  def self.fetch_messages(imap, since_date)
    LoggerService.info("Попытка подключения к папке 'SENT' \"#{AppConfig.email_sent_folder}\" на сервере \"#{AppConfig.imap_host}\" - \"#{AppConfig.email_user_name}\"")
    imap = connect if imap.disconnected?

    begin
  	  imap.select(AppConfig.email_sent_folder)
    rescue => e
      LoggerService.warn("Ошибка подключения к папке 'SENT' \"#{e.message}\"")
      sleep(AppConfig.imap_connection_retry_delay)
      imap = connect if imap.disconnected?
      retry
    end

    LoggerService.info("Успешно: подключение к папке 'SENT' \"#{AppConfig.email_sent_folder}\" на сервере \"#{AppConfig.imap_host}\" - \"#{AppConfig.email_user_name}\"")

  	search_criteria = ['SINCE', since_date.strftime("%d-%b-%Y")]
    # search_criteria = ['UNSEEN']

    LoggerService.info("поиск писем по критерию \"#{search_criteria}\" на сервере \"#{AppConfig.imap_host}\" - \"#{AppConfig.email_user_name}\"")

    begin
      mails =
      imap.search(search_criteria).map do |msg_id|
      	msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
      	Mail.read_from_string(msg)
      end
    rescue => e
      LoggerService.info("неудачно: поиск писем по критерию: #{e.message}")
      sleep(AppConfig.imap_connection_retry_delay)
      imap = connect if imap.disconnected?
      retry
    end

    offset = since_date.in_time_zone(AppConfig.admin_time_zone).strftime('%:z').to_i
    LoggerService.info("Найдено #{mails.size} писем на сервере, начиная с #{since_date.in_time_zone(AppConfig.admin_time_zone).strftime("%d-%b-%Y #{offset}:00:00 %z")}")

    mails
  end
end
