require_relative 'ping'
require 'socket'
require 'timeout'

class Ping::ICMP < Ping
  ICMP_ECHOREPLY = 0 # Echo reply
  ICMP_ECHO      = 8 # Echo request
  ICMP_SUBCODE   = 0

  attr_reader :data_size

  def initialize(host=nil, port=nil, timeout=5)
    raise 'requires root privileges' if Process.euid > 0

    @seq = 0
    @data_size = 56
    @data = ''

    0.upto(@data_size){ |n| @data << (n % 256).chr }

    @pid  = Process.pid & 0xffff

    super(host, timeout)
  end

  def ping(host = @host)
    super(host)
    bool = false

    socket = Socket.new(
      Socket::PF_INET,
      Socket::SOCK_RAW,
      Socket::IPPROTO_ICMP
    )

    @seq = (@seq + 1) % 65536
    pstring = 'C2 n3 A' << @data_size.to_s
    timeout = @timeout

    checksum = 0
    msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @pid, @seq, @data].pack(pstring)

    checksum = checksum(msg)
    msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @pid, @seq, @data].pack(pstring)

    begin
      saddr = Socket.pack_sockaddr_in(0, host)
    rescue Exception
      socket.close unless socket.closed?
      return bool
    end

    start_time = Time.now

    socket.send(msg, 0, saddr) # Send the message

    begin
      Timeout.timeout(@timeout){
        while true
          io_array = select([socket], nil, nil, timeout)

          if io_array.nil? || io_array[0].empty?
            return false
          end

          pid = nil
          seq = nil

          data = socket.recvfrom(1500).first
          type = data[20, 2].unpack('C2').first


          case type
            when ICMP_ECHOREPLY
              if data.length > 56
                pid, seq = data[24, 4].unpack('n3')
              end
          end

          if pid == @pid && seq == @seq && type == ICMP_ECHOREPLY
            bool = true
            break
          end
        end
      }
    rescue Exception => err
      @exception = err
    ensure
      socket.close if socket
    end

    @duration = Time.now - start_time if bool

    return bool
  end

  private

  def checksum(msg)
    length    = msg.length
    num_short = length / 2
    check     = 0

    msg.unpack("n#{num_short}").each do |short|
      check += short
    end

    if length % 2 > 0
      check += msg[length-1, 1].unpack('C').first << 8
    end

    check = (check >> 16) + (check & 0xffff)
    return (~((check >> 16) + check) & 0xffff)
  end
  end
