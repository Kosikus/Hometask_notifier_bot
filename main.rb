# frozen_string_literal: true

# Временная зона для rufus-scheduler
ENV['TZ'] = 'Europe/Moscow'

ROOT_PATH = File.expand_path('.', __dir__)
USERS_DATA_FILE_PATH = File.join(ROOT_PATH, 'app/data/students_info.json')

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

require File.join(ROOT_PATH, 'app/config/app_config.rb')

# Загрузка переменных окружения
Dotenv.load(File.join(ROOT_PATH, '.env'))

require File.join(ROOT_PATH, 'app/services/localization_service.rb')
require File.join(ROOT_PATH, 'app/services/logger_service.rb')
require File.join(ROOT_PATH, 'app/services/mail_service.rb')
require File.join(ROOT_PATH, 'app/services/notification_service.rb')
require File.join(ROOT_PATH, 'app/bot/email_notifier_bot.rb')
require File.join(ROOT_PATH, 'app/managers/user_manager.rb')

LocalizationService.new

EmailNotifierBot.new.run
