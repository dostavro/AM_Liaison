require 'logging'
require 'blather/client/dsl'

include Logging.globally

$stdout.sync = true

Logging.appenders.stdout('stdout',
                         :layout => Logging.layouts.pattern(:date_pattern => '%F %T %z',
                                                            :pattern => '[%d] %-5l %m\n',
                                                            :color_scheme => 'default'))
Logging.logger.root.appenders = 'stdout'
Logging.logger.root.level = :info

PUBSUB_CONFIGURE = Blather::Stanza::X.new({
      :type => :submit,
      :fields => [
        { :var => "FORM_TYPE", :type => 'hidden', :value => "http://jabber.org/protocol/pubsub#node_config" },
        { :var => "pubsub#persist_items", :value => "0" },
        { :var => "pubsub#max_items", :value => "0" },
        { :var => "pubsub#notify_retract",  :value => "0" },
        { :var => "pubsub#publish_model", :value => "open" }]
    })

HOST = 'dsw-laptop'

class OmfAM
  
  DISCONNECT_WAIT = 5

  include Blather::DSL

  attr_accessor :host, :urn, :pwd

  def initialize(urn, host, pswd)

    @urn = urn
    @host = host
    @pwd = pswd
    @ps_host = "pubsub.#{@host}"

    when_ready do
      logger.info "Connected to: #{jid}"

      create_topic(urn, @ps_host)
      subscribe(urn, @ps_host)
      
    end
  end
  
  def create_topic(topic, host)
    pubsub.create(topic, host, PUBSUB_CONFIGURE)
  end

  def subscribe(topic, host)
    pubsub.subscribe(topic, nil, host) do |s|
      if s.error?
	logger.info "Failed to subscribe to the topic '#{topic}' at host '#{host}'"
      else
	logger.info "Successfully subscribed to the topic '#{topic}' at host '#{host}'"
      end
    end
  end

  def connect
    client.setup("#@urn@#@host", @pwd)
    client.run
  end

  # Try to clean up pubsub topics, and wait for DISCONNECT_WAIT seconds, then shutdown event machine loop
  def disconnect
    pubsub.affiliations(@ps_host) do |a|
      my_pubsub_topics = a[:owner] ? a[:owner].size : 0
      if my_pubsub_topics > 0
	logger.info "Cleaning #{my_pubsub_topics} pubsub topic(s)"
	a[:owner].each { |topic| pubsub.delete(topic, @ps_host); logger.info "Deleting topic: #{topic}" }
      else
	logger.info "Disconnecting now"
	pubsub.disconnect(@host)
      end
    end
    logger.info "Disconnecting in #{DISCONNECT_WAIT} seconds"
    EM.add_timer(DISCONNECT_WAIT) do
      shutdown
    end
  end

end

omf_am = OmfAM.new('omf_am', HOST, 'pw')

omf_am.message :chat? do |m|
  logger.info "#{m.from} sent this: #{m.body}"
end


omf_am.pubsub_event do |e|
  logger.info "event in topic '#{e}'"
end


EM.run do
  omf_am.connect
  trap(:INT) { omf_am.disconnect }
  trap(:TERM) { omf_am.disconnect }
end
