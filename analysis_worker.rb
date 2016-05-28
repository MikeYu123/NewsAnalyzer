require 'sidekiq'
load File.expand_path('../messages_consumer.rb', __FILE__)


Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'sidekiq_jobs', :size => 1 }
end

class AnalysisWorker
  include Sidekiq::Worker
  def perform msg
    MessagesConsumer.new.process_message msg
  end
end
