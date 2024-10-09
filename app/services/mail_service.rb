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

      LoggerService.info("Попытка подключения к IMAP-серверу #{AppConfig.imap_host} на порту #{AppConfig.imap_port}")

    	imap = Net::IMAP.new(AppConfig.imap_host, port: AppConfig.imap_port, ssl: true)
      LoggerService.info("Успешно: подключение к IMAP-серверу #{AppConfig.imap_host}")

    	imap.login(AppConfig.email_user_name, AppConfig.email_password)
      LoggerService.info("Успешно: Аутентификация пользователя #{AppConfig.email_user_name}")

    	imap

    rescue Net::IMAP::NoResponseError => e
<<<<<<< HEAD
      LoggerService.error("Ошибка аутентификации на IMAP-сервере: \"#{e.message}\"")
=======
      LoggerService.error("Ошибка аутентификации на IMAP-сервере: #{e.message}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf
      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue SocketError => e
<<<<<<< HEAD
      LoggerService.error("Нет подключения к сети или неверно указан хост. Не удалось подключиться к IMAP-серверу \"#{AppConfig.imap_host}: #{e.message}\"")
=======
      LoggerService.error("Нет подключения к сети или неверно указан хост. Не удалось подключиться к IMAP-серверу #{AppConfig.imap_host}: #{e.message}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf
      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue Net::IMAP::ByeResponseError => e
<<<<<<< HEAD
      LoggerService.error("IMAP-сервер неожиданно разорвал соединение: \"#{e.message}\"")
=======
      LoggerService.error("IMAP-сервер неожиданно разорвал соединение: #{e.message}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf
      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    rescue => e
<<<<<<< HEAD
      LoggerService.error("Неизвестная ошибка при подключении к серверу: \"#{e.message}\"")
=======
      LoggerService.error("Неизвестная ошибка при подключении к серверу. #{e.class}: #{e.message}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf
      LoggerService.debug(e.backtrace.join("\n"))
      retries += 1
      retry
    end
  end

  def self.fetch_messages(imap, since_date)
<<<<<<< HEAD
    LoggerService.info("Попытка подключения к папке 'SENT' \"#{AppConfig.email_sent_folder}\" на сервере \"#{AppConfig.imap_host}\" - \"#{AppConfig.email_user_name}\"")

    imap = connect if imap.disconnected?
=======
    LoggerService.info("Попытка подключения к папке 'SENT' #{AppConfig.email_sent_folder} на сервере #{AppConfig.imap_host} #{AppConfig.email_user_name}")

    connect if imap.disconnected?
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf

    begin
  	  imap.select(AppConfig.email_sent_folder)
    rescue => e
<<<<<<< HEAD
      LoggerService.warn("Ошибка подключения к папке 'SENT' \"#{e.message}\"")
    end    

    LoggerService.info("Успешно: подключение к папке 'SENT' \"#{AppConfig.email_sent_folder}\" на сервере \"#{AppConfig.imap_host}\" -  \"#{AppConfig.email_user_name}\"")
=======
      LoggerService.warn("ОШИБКА!!! #{e.message}")
    end    

    LoggerService.info("Успешно: подключение к папке 'SENT' #{AppConfig.email_sent_folder} на сервере #{AppConfig.imap_host} #{AppConfig.email_user_name}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf

  	search_criteria = ['SINCE', since_date.strftime("%d-%b-%Y")]
    # search_criteria = ['UNSEEN']

<<<<<<< HEAD
    LoggerService.info("Поиск писем по критерию \"#{search_criteria}\" на сервере \"#{AppConfig.imap_host}\" - \"#{AppConfig.email_user_name}\"")
=======
    LoggerService.info("Поиск писем по критерию #{search_criteria} на сервере #{AppConfig.imap_host} #{AppConfig.email_user_name}")
>>>>>>> af7d03697e6f0dad7d4c62e67334171ebe0470cf

    mails = 
    imap.search(search_criteria).map do |msg_id|
    	msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
    	Mail.read_from_string(msg)
    end

    offset = since_date.in_time_zone(AppConfig.admin_time_zone).strftime("%:z").to_i
    LoggerService.info("Найдено #{mails.size} писем на сервере, начиная с #{since_date.in_time_zone(AppConfig.admin_time_zone).strftime("%d-%b-%Y #{offset}:00:00 %z")}")

    mails
  end
end
