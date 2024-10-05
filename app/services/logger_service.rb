class LoggerService
  def self.logger
	  @logger ||= Logger.new(File.join(ROOT_PATH, AppConfig.log_file_path))
  end

  def self.info(message)
	  logger.info(message)
  end

  def self.error(message)
	  logger.error(message)
  end
end
