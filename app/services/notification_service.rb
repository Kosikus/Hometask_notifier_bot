class NotificationService
  # оправка оповещений в тг-бот
  def self.send_notifications(bot, users, mails)
  	# TODO
    users.each do |user|
      mails.each do |mail|
        next unless eligible_for_notification?(Time.now.in_time_zone(AppConfig.admin_time_zone), user, mail)

        send_notification(bot, user, mail)

        UserManager.update_last_email_sent_time(
          USERS_DATA_FILE_PATH,
          user[:id],
          mail.date.in_time_zone(AppConfig.admin_time_zone)
        )

        sleep(2)
        send_notification(bot, {telegram_id: AppConfig.admin_tg_id}, mail) # для меня
      end
    end
  end

  # подходит письмо для оповещения?
  def self.eligible_for_notification?(now_admin_time, user, mail)
  	# TODO
    mail_date = mail.date.in_time_zone(AppConfig.admin_time_zone)
    user_timezone = ActiveSupport::TimeZone[user[:time_zone]]

    mail.to.include?(user[:email]) &&
    user[:active] &&
    mail_date > Time.parse(user[:last_message_send]) &&
    
    notification_time?(
      now_admin_time, 
      user[:weekend_notification_time][:start], 
      user[:weekend_notification_time][:end], 
      user_timezone
    )
  end

  # можно ли отправить сообщение в указанные пользователем рамки?
  def self.notification_time?(now_admin_time, user_start_time_str, user_stop_time_str, user_time_zone)
    # TODO
    user_start_time = user_time_zone.parse(user_start_time_str)
    user_stop_time = user_time_zone.parse(user_stop_time_str)

    now_admin_time >= user_start_time && now_admin_time <= user_stop_time
  end

  def self.send_notification(bot, user, mail)
  	# TODO
    content = generate_mail_content(mail)

    bot.api.send_message(chat_id: user[:telegram_id], text: content, parse_mode: 'HTML')
  end

  # формирование текста сообщения для отправки из письма 
  def self.generate_mail_content(mail)
  	# TODO
    html_content = mail.html_part ? mail.html_part.body.decoded : mail.body.decoded
    doc = Nokogiri::HTML(html_content, nil, 'UTF-8')
    text_content = doc.xpath('//text()').map(&:text).join("\n")
    text_content = text_content.gsub("\u00A0", ' ')

    content = Sanitize.clean(text_content)

    full_tg_message = "От: #{mail.from.first}\n" +
                      "Кому: #{mail.to.first}\n" +
                      "<b>Тема: #{mail.subject}</b>\n" +
                      "Дата: #{format_mail_date(mail.date, AppConfig.admin_time_zone)}\n" +
                      "Тело:\n#{text_content}"

    shorten_content(full_tg_message) + "-" * 50
  end

  # Перевод даты в мою временную зону и с использованием названий русских месяцев
  def self.format_mail_date(mail_date, admin_time_zone)
    raise ArgumentError, "Expected DateTime, got #{mail_date.class}" unless mail_date.is_a?(DateTime)

    # Переводим DateTime в базовую временную зону
    admin_mail_date = mail_date.in_time_zone(admin_time_zone)

    # Форматируем дату с использованием I18n
    I18n.l(admin_mail_date, format: :default)
  end

  # сокращение письма до BOT_MESSAGE_CHARACTER_LIMIT знаков
  def self.shorten_content(content)
    if content.size > AppConfig.bot_message_character_limit
      content = content[0, AppConfig.bot_message_character_limit] + "\n\n" + "-----&ltчасть сообщения скрыта&gt-----"
    end

    content + "\n" 
  end
end
