class LoggerService
  def self.logger
    unless @logger
      # File.delete(File.join(ROOT_PATH, AppConfig.log_file_path)) if File.exist?(File.join(ROOT_PATH, AppConfig.log_file_path))
      @logger = Logger.new(File.join(ROOT_PATH, AppConfig.log_file_path), 10, 10 * 1000 * 1024)

      @logger << "\n\n# Logfile created on #{Time.now.in_time_zone(AppConfig.admin_time_zone)}\n"
      
      # Настройка форматирования логов
      @logger.formatter = proc do |severity, datetime, progname, msg|
        # Перевод времени в зону Europe/Moscow
        "#{datetime.in_time_zone(AppConfig.admin_time_zone).strftime('%d-%m-%Y %H:%M:%S %z')} [#{severity}] #{msg}\n"
      end
    end
    
    @logger
  end

  def self.debug(message)
    logger.debug(message)
  end

  def self.info(message)
	  logger.info(message)
  end

  def self.warn(message)
	  logger.warn(message)
  end

  def self.error(message)
    logger.error(message)
  end

  def self.fatal(message)
    logger.fatal(message)
  end
end
