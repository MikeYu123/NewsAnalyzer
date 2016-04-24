require 'ruby-kafka'
require 'json'

class KafkaConsumer
  #TODO: config.yml
  MESSAGE_TIMEOUT = 120
  attr_accessor :topic_name
  attr_accessor :group_name
  attr_accessor :consumer
  attr_accessor :seeders
  def initialize args={}
    @seeders = ['localhost:9092']
    @topic_name = args[:topic_name]
    @group_name = args[:group_name]
    kafka = Kafka.new seed_brokers: @seeders
    @consumer = kafka.consumer group_id: @group_name
    @consumer.subscribe @topic_name
  end

  def start_cycle
    @consumer.each_message(max_wait_time: MESSAGE_TIMEOUT) do |message|
      process_message(message.value)
    end
  end

  def process_message message
    msg = JSON.parse(message.force_encoding 'utf-8')
  end
end
