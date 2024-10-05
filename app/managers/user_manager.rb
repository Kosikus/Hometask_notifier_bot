class UserManager
  # Чтение и парсинг данных из JSON-файла	
  def self.load_users(users_data_file_path)
    begin
      LoggerService.info("Попытка подгрузить студентов из #{users_data_file_path}")
      users = JSON.parse(File.read(users_data_file_path), symbolize_names: true)
      LoggerService.info("Успешно: студенты подгружены из #{users_data_file_path}")

      users
    rescue Errno::ENOENT => e
      LoggerService.fatal("Файл не найден: #{users_data_file_path} - #{e.message}")
      exit(1)
    rescue JSON::ParserError => e
      LoggerService.fatal("Неверный форман json-файла: #{users_data_file_path} - #{e.message}")
      exit(1)
    rescue Errno::EACCES => e
      LoggerService.fatal("Файл защищён от чтения: #{users_data_file_path} - #{e.message}")
      exit(1)
    rescue StandardError => e
      LoggerService.fatal("Неизвестная ошибка при попытке чтения из файла #{users_data_file_path}: #{e.message}")
      exit(1)
    end
  end

  # Метод для записи в JSON
  def self.update_last_email_sent_time(users_data_file_path, user_id, new_time)
    data = load_users(users_data_file_path)
    user = data.find { |user| user[:id] == user_id }

    user[:last_message_send] = new_time.iso8601 if user

    begin
      LoggerService.info("Попытка обновить время отправления последнего письма для id=#{user[:id]} в #{users_data_file_path}")
      File.write(users_data_file_path, JSON.pretty_generate(data))
      LoggerService.info("Успешно: обновлено время отправления последнего письма для id=#{user[:id]} в #{users_data_file_path}")
    rescue Errno::ENOENT => e
      LoggerService.fatal("Файл не найден: #{users_data_file_path} - #{e.message}")
      exit(1)
    rescue Errno::EACCES => e
      LoggerService.fatal("Файл защищён от записи: #{users_data_file_path} - #{e.message}")
      exit(1)
    rescue StandardError => e
      LoggerService.fatal("Неизвестная ошибка при записи в файл #{users_data_file_path}: #{e.message}")
      exit(1)
    end
  end
end
