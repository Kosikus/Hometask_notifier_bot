class MailService
  def self.connect
  	imap = Net::IMAP.new(AppConfig.imap_host, port: AppConfig.imap_port, ssl: true)
  	imap.login(AppConfig.email_user_name, AppConfig.email_password)
  	imap
  end

  def self.fetch_messages(imap, since_date)
  	imap.select(AppConfig.email_sent_folder)

  	search_criteria = ['SINCE', since_date.strftime("%d-%b-%Y")]

    imap.search(search_criteria).map do |msg_id|
    	msg = imap.fetch(msg_id, 'RFC822')[0].attr['RFC822']
    	Mail.read_from_string(msg)
    end
  end
end