require 'json'
load File.expand_path('../article_analyzer.rb', __FILE__)

class MessagesConsumer
  def process_message message
    msg = JSON.parse(message.force_encoding 'utf-8')
    ArticleAnalyzer.analyze_article(msg)
  end

end
