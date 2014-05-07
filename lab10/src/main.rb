require 'socket'
require 'pry'

UDPSock = UDPSocket.new
addr_any = ['0.0.0.0', 33333]
UDPSock.bind(addr_any[0], addr_any[1])


addr_broadcast = ['<broadcast>', 33333]
UDPSock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)

thread_recieve = Thread.new do
  loop do
    data, addr = UDPSock.recvfrom(1024)
    puts "From addr: '%s', msg: '%s'" % [addr[2], data]
  end
end

loop do
  data = gets
  UDPSock.send(data, 0, addr_broadcast[0], addr_broadcast[1])
end

thread_recieve.join

UDPSock.close
