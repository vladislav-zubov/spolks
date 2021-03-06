require 'socket'
require 'bit-struct'
require 'pry'


class IP < BitStruct
  unsigned    :ip_v,     4,     "Version"
  unsigned    :ip_hl,    4,     "Header length"
  unsigned    :ip_tos,   8,     "TOS"
  unsigned    :ip_len,  16,     "Length"
  unsigned    :ip_id,   16,     "ID"
  unsigned    :ip_off,  16,     "Frag offset"
  unsigned    :ip_ttl,   8,     "TTL"
  unsigned    :ip_p,     8,     "Protocol"
  unsigned    :ip_sum,  16,     "Checksum"
  octets      :ip_src,  32,     "Source addr"
  octets      :ip_dst,  32,     "Dest addr"
  rest        :body,            "Body of message"

  note "     rest is application defined message body"

  initial_value.ip_v    = 4
  initial_value.ip_hl   = 5
end

class ICMP < IP
  unsigned    :icmp_type,   8,    "Message type"
  unsigned    :icmp_code,   8,    "Message code"
  unsigned    :icmp_cksum,  16,   "ICMP checksum"
  unsigned    :icmp_id,     16
  unsigned    :icmp_seq,    16
  rest        :body,              "Body of ICMP message"
end

# Example of using the IP class to receive ping (ICMP) messages.

begin
  rsock = Socket.open(Socket::PF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
rescue Errno::EPERM
  $stderr.puts "Must run #{$0} as root."
  exit!
end

begin
  ssock = Socket.open(Socket::PF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
  ssock.setsockopt(Socket::SOL_IP, Socket::IP_HDRINCL, true)
    # IP_HDRINCL isn't necessary to send ICMP, but we are inheriting
    # ICMP from IP, so the header is included in this example.
rescue Errno::EPERM
  $stderr.puts "Must run #{$0} as root."
  exit!
end

addr = Socket.pack_sockaddr_in(1024, "localhost")
5.times do |i|
  icmp = ICMP.new do |b|
    # ip_v and ip_hl are set for us by IP class
    b.ip_tos  = 0
    b.ip_id   = i
    b.ip_off  = 0 ## ?
    b.ip_ttl  = 64
    b.ip_p    = Socket::IPPROTO_ICMP
    b.ip_src  = "127.0.0.2"
    b.ip_dst  = "127.0.0.1"
    b.body    = Time.now.to_s ## ?
    b.ip_len  = b.length
    b.ip_sum  = 0 ## ?
  end

  ssock.send(icmp, 0, addr)
  sleep 1
end
