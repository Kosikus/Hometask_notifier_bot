# Временная зона для rufus-scheduler
ENV['TZ'] = 'Europe/Moscow'

require 'json'
require 'time'
require 'net/imap'
require 'date'
require 'mail'
require 'telegram/bot'
require 'dotenv'
require 'active_support/time'
require 'tzinfo/data'
require 'base64'
require 'nokogiri'
require 'sanitize'
require 'rufus-scheduler'
require 'i18n'

# Загрузка переменных окружения
Dotenv.load

# Учетные данные
username = ENV['YANDEX_USERNAME']
password = ENV['YANDEX_PASSWORD']
sent_folder = ENV['SENT_YANDEX_FOLDER']
MY_TG_ID = ENV['ADMIN_TG_ID']
TOKEN = ENV['TELEGRAM_BOT_TOKEN']
json_file_path = './data/students_info.json'

base_timezone = ActiveSupport::TimeZone[ENV['TZ']]

# Устанавливаем доступные локали и дефолтную
I18n.config.available_locales = [:ru]
I18n.default_locale = :ru

# Задаем переводы для форматов даты и времени
I18n.backend.store_translations(:ru, date: {
  formats: {
    default: "%d %B %H:%M МСК"
  },
  month_names: %w[заглушка Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь Октябрь Ноябрь Декабрь],
  abbr_month_names: %w[заглушка Янв Фев Мар Апр Май Июн Июл Авг Сен Окт Ноя Дек]
})
I18n.backend.store_translations(:ru, time: {
  formats: {
    default: "%d %B %H:%M МСК"
  }
})

# Чтение и парсинг данных из JSON-файла
def load_users(json_file_path)
  JSON.parse(File.read(json_file_path), symbolize_names: true)
end

# Метод для записи в JSON
def update_last_message_send(json_file_path, user_id, new_time)
  data = load_users(json_file_path)
  user = data.find { |u| u[:id] == user_id }
  user[:last_message_send] = new_time.iso8601 if user
  File.write(json_file_path, JSON.pretty_generate(data))
end

# Функция для проверки, находится ли текущее время в пределах уведомлений
def notification_time?(current_time, start_time_str, end_time_str, timezone)
  # Преобразуем строки времени в объект времени в нужном часовом поясе
  start_time = timezone.parse(start_time_str)
  end_time = timezone.parse(end_time_str)
  
  # Проверяем, находится ли текущее время в диапазоне уведомлений
  current_time >= start_time && current_time <= end_time
end

# Перевод даты в мою временную зону и с использованием названий русских месяцев
def format_mail_date(mail_date, timezone)
  raise ArgumentError, "Expected DateTime, got #{mail_date.class}" unless mail_date.is_a?(DateTime)

  # Переводим DateTime в базовую временную зону
  base_time = timezone.local(mail_date.year, mail_date.month, mail_date.day, mail_date.hour, mail_date.min, mail_date.sec)

  # Форматируем дату с использованием I18n
  I18n.l(base_time, format: :default)
end

# Функция отправки уведомления в Telegram
def send_notification(bot, user, mail, base_timezone)
  text_content = generate_mail_content(mail)
  tg_message = "От: #{mail.from.first}\n" +
               "Кому: #{mail.to.first}\n" +
               "<b>Тема: #{mail.subject}</b>\n" +
               "Дата: #{format_mail_date(mail.date, base_timezone)}\n" +
               "Тело:\n#{text_content}"

  bot.api.send_message(chat_id: user[:telegram_id], text: tg_message + "-" * 50, parse_mode: 'HTML')
end

# Генерация текстового контента из письма
def generate_mail_content(mail)
  html_content = mail.html_part ? mail.html_part.body.decoded : mail.body.decoded
  doc = Nokogiri::HTML(html_content, nil, 'UTF-8')
  text_content = doc.xpath('//text()').map(&:text).join("\n")
  text_content = text_content.gsub("\u00A0", ' ')

  content = Sanitize.clean(text_content)
  if content.size > 500
    content[0,500] + "\n\n" + "-----&ltчасть сообщения скрыта&gt-----" + "\n"
  else
    content[0, 500] + "\n"  
  end
end

# Создаем планировщик
scheduler = Rufus::Scheduler.new

# Подключаемся к почтовому серверу Yandex один раз
imap = Net::IMAP.new('imap.yandex.ru', port: 993, ssl: true)
imap.login(username, password)

# Запускаем бота и планировщик в одном потоке
Telegram::Bot::Client.run(TOKEN) do |bot|
  # Планировщик проверяет почту каждые 5 минут
  scheduler.every '15s' do
    imap.select(sent_folder)

    # Определяем время начала предыдущего дня
    now = Time.now
    yesterday = base_timezone.local(now.year, now.month, now.day).yesterday

    search_criteria = ['SINCE', yesterday.strftime("%d-%b-%Y")]
    message_ids = imap.search(search_criteria)

    # Обрабатываем письма
    message_ids.each do |msg_id|
      msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
      mail = Mail.read_from_string(msg)
      now_in_tz = DateTime.now.in_time_zone(base_timezone)
   
      # Загружаем пользователей
      users = load_users(json_file_path)

      # Поиск получателя в списке пользователей
      users.each do |user|
        # перевод даты отправки письма в базовую временную зону
        mail_date = mail.date.in_time_zone(base_timezone)
        user_timezone = ActiveSupport::TimeZone[user[:time_zone]]

        last_message_send = user[:last_message_send] ? Time.parse(user[:last_message_send]) : nil

        next if !user[:active] ||
                !mail.to.include?(user[:email]) ||
                (mail_date <= last_message_send) || # считанное письмо старое
                !(notification_time?(now_in_tz, user[:weekend_notification_time][:start], user[:weekend_notification_time][:end], user_timezone) ||
                notification_time?(now_in_tz, user[:weekday_notification_time][:start], user[:weekday_notification_time][:end], user_timezone))

        # Проверка времени уведомленийru
        if (now_in_tz.saturday? || now_in_tz.sunday?) &&
           notification_time?(now_in_tz, user[:weekend_notification_time][:start], user[:weekend_notification_time][:end], user_timezone)
          send_notification(bot, user, mail, base_timezone)
          send_notification(bot, {telegram_id: MY_TG_ID}, mail, base_timezone)
          # Обновляем last_message_send
          update_last_message_send(json_file_path, user[:id], mail_date)
        elsif notification_time?(now_in_tz, user[:weekday_notification_time][:start], user[:weekday_notification_time][:end], user_timezone)
          send_notification(bot, user, mail, base_timezone)
          send_notification(bot, {telegram_id: MY_TG_ID}, mail, base_timezone)
          # Обновляем last_message_send
          update_last_message_send(json_file_path, user[:id], mail_date)
        end
      end
    end
  end

  # Обработка команд от пользователей
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Привет! Я бот, который уведомит тебя о новых письмах и могу реагировать на команды.")
    when '/say_hello'
      bot.api.send_message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}!")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Неизвестная команда. Попробуй /start или /say_hello.")
    end
  end

  # Закрываем соединение
  imap.logout
  imap.disconnect
end

