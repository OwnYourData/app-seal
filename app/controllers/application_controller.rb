class ApplicationController < ActionController::Base
	protect_from_forgery with: :exception
	before_action :set_locale

	def default_url_options(options={})
		I18n.locale == :en ? {} : { locale: I18n.locale }
	end

	private

	def extract_locale_from_accept_language_header
		hal = request.env['HTTP_ACCEPT_LANGUAGE']
		if hal
			retval = hal.scan(/^[a-z]{2}/).first
			if "-en-de-".split(retval).count == 2
				retval
			else
				I18n.default_locale
			end
		else
			I18n.default_locale
		end
	end

	def set_locale
		I18n.locale = params[:locale] || extract_locale_from_accept_language_header
		Rails.application.routes.default_url_options[:locale]= I18n.locale
	end
end
