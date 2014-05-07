require 'socket'
require 'ipaddr'
require 'pry'

MULTICAST_ADDR = "225.4.5.6"
PORT= 33333

socket = UDPSocket.open
socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 5)


th = Thread.new do
  ip =  IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
  sock = UDPSocket.new
  sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
  sock.bind(Socket::INADDR_ANY, PORT)
  loop do
    msg, info = sock.recvfrom(1024)
    sock.send('ping echo', 0, info[2], PORT) if msg === "ping\n"
    puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]} len #{msg.size}"
  end
  sock.close
end

loop do
  data = gets
  socket.send(data, 0, MULTICAST_ADDR, PORT)
end

th.join

socket.close
