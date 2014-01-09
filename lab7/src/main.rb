require 'slop'
require 'pry'
require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require_relative 'udp_server.rb'
require_relative 'tcp_server.rb'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

tcp = TcpServer.new
tcp_socket  = tcp.listen(opts)

udp = UdpServer.new
udp_socket = udp.listen(opts)

loop do
  result = IO.select([udp_socket.fd, tcp_socket.fd])
  result[0].each do |socket|
    tcp.connected_user if socket == tcp_socket.fd
    udp.connected_user if socket == udp_socket.fd
  end
end