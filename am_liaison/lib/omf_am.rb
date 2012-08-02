require 'abstract_am'
require 'omf_common'
require 'uri'

# OmfAM is a class for Aggregate Managers of OMF testbeds.
#
# @attr [OmfCommon::Comm] comm The XMPP communication interface to the OMF AM
class OmfAM < AbstractAM

  include OmfCommon

  attr_reader :comm

  # create a new instance of an OMF AM and connect to its pubsub topic
  #
  # @param [String] urn uniform resource name of the AM
  # @param [URI] uri uniform resource identifier of the AM
  # @return [OmfAM]
  def initialize(urn, uri)
    super(urn, URI.parse(uri))
    
    @comm = OmfCommon::Comm.new('xmpp')

    @comm.when_ready do
      logger.info "CONNECTED: #{@comm.jid.inspect}"
      
      @comm.subscribe(urn, @uri.host) 
    end
    @comm.connect('broker', 'pw', @uri.host)
  end

  # send a create message to the AM
  #
  # @param [UUID] res_uuid The resource's uuid
  def create_resource(res_uuid)
    @comm.publish(@urn, Message.create { |v| v.property('uuid', res_uuid) }, @uri.host)
  end

  # send a release message to the AM
  def release_resource
    #TODO: send a release message to the AM
  end

  # a way to discover available resources of the AMs
  def discover_resources
    #TODO: a way to discover the resources of the AM
  end
  
  # disconnect from this AM by unsubscribing from its topic
  # and disconnecting from the XMPP server
  def disconnect
    @comm.unsubscribe(@uri.host) 
    @comm.disconnect
  end

  # string representation
  def to_s
    "urn: #@urn, uri: #@uri"
  end

end
