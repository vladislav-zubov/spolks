class Ping

  attr_accessor :host
  attr_accessor :timeout
  attr_reader :exception
  attr_reader :warning
  attr_reader :duration

  def initialize(host=nil, timeout=5)
     @host      = host
     @timeout   = timeout
     @exception = nil
     @warning   = nil
     @duration  = nil

     yield self if block_given?
  end

  def ping(host = @host)
     raise ArgumentError, 'no host specified' unless host
     @exception = nil
     @warning   = nil
     @duration  = nil
  end

end
