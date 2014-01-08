require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'slop'
require 'pry'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

prev_packet = nil
packet = Network::Packet.new

Network::DatagramSocket.listen opts do |socket|
  XIO::XFile.write opts do |file|
    loop do
      rs, = socket.select rs: true
      break unless rs

      data, who = socket.recv_nonblock
      socket.send Network::ACK, who
      packet.read data 
      break if data.empty? or data == Network::FIN
      if prev_packet && packet.num_packet != prev_packet.num_packet
        file.write packet.data
      end
      prev_packet = packet.dup
    end
  end
end
