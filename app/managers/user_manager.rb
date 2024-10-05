class UserManager
  # Чтение и парсинг данных из JSON-файла	
  def self.load_users(users_data_file_path)
  	JSON.parse(File.read(users_data_file_path), symbolize_names: true)
  end

  # Метод для записи в JSON
  def self.update_last_email_sent_time(users_data_file_path, user_id, new_time)
    data = load_users(users_data_file_path)
    user = data.find { |user| user[:id] == user_id }

    user[:last_message_send] = new_time.iso8601 if user
    File.write(users_data_file_path, JSON.pretty_generate(data))
  end
end
