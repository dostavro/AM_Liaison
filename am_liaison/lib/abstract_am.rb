# It defines an abstract Aggregate Manager of a serving testbed.
#
# @attr [String] urn The uniform resource name of the AM
# @attr [URI] uri The uniform resource identifier of the AM
class AbstractAM

  attr_accessor :urn, :uri

  def initialize(urn, uri)
    @urn, @uri = urn, uri
  end

end
