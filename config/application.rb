require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require "action_controller/railtie"
require "action_mailer/railtie"
# require "active_resource/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Cenit
  class Application < Rails::Application

    config.autoload_paths += %W(#{config.root}/lib) #/**/*.rb
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.to_prepare do
      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.after_initialize do

      puts 'Clearing LOCKS'
      Cenit::Locker.clear

      puts 'DELETING OLD Consumers'
      RabbitConsumer.delete_all

      Account.all.each do |account|

        next if account.meta.present?

        Account.current = account

        ThreadToken.destroy_all
        Setup::Task.all.any_in(status: Setup::Task::ACTIVE_STATUS).update_all(status: :broken)

      end

      Account.current = nil

      Cenit::ApplicationParameter.instance_eval do
        include Setup::CenitScoped
        build_in_data_type.referenced_by(:name)
      end

      Cenit::OauthAccessGrant.instance_eval do
        include Setup::CenitScoped
        deny :all
        allow :index, :delete
      end

      Setup::BuildInDataType.each do |build_in|
        model = build_in.model
        namespace = model.to_s.split('::')
        name = namespace.pop
        namespace = namespace.join('::')
        Setup::CenitDataType.find_or_create_by(namespace: namespace, name: name)
      end
    end

    if Rails.env.production? &&
      (notifier_email = ENV['NOTIFIER_EMAIL']) &&
      (exception_recipients = ENV['EXCEPTION_RECIPIENTS'])
      Rails.application.config.middleware.use ExceptionNotification::Rack,
                                              email: {
                                                email_prefix: "[Cenit Error #{Rails.env}] ",
                                                sender_address: %{"notifier" <#{notifier_email}>},
                                                exception_recipients: exception_recipients.split(',')
                                              }
    end

  end
end
