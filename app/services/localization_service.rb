class LocalizationService
  def initialize(locale = :ru)
    @locale = locale
	  configure_i18n
  end

  private

  def configure_i18n
	# Устанавливаем доступные локали и дефолтную
    I18n.config.available_locales = [:ru]
    I18n.default_locale = :ru

    # Задаем переводы для форматов даты и времени
    I18n.backend.store_translations(:ru, {
      date: {
        formats: {
          default: "%d %B %H:%M МСК"
        },
        month_names: %w[заглушка Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь Октябрь Ноябрь Декабрь],
        abbr_month_names: %w[заглушка Янв Фев Мар Апр Май Июн Июл Авг Сен Окт Ноя Дек]
      },
      time: {
        formats: {
          default: "%d %B %H:%M МСК"
        }
      }
    })
  end
end