require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'slop'
require 'pry'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

whos = []

Network::DatagramSocket.listen opts do |socket|
  loop do
    data, who = socket.recv
    if !whos.include? who
      Thread.new do
        XIO::XFile.write opts do |file|
          sock_client = Network::DatagramSocket.new(host: opts[:host], port: 0)
          sock_client.bind
          port = sock_client.get_port
          packet_with_port = Network::Packet.new num_packet: 0,len: port.to_s.length, data: port.to_s, inf_or_data: 3
          socket.send packet_with_port.to_binary_s, who
          prev_packet = nil
          packet = Network::Packet.new
          loop do
            rs, = sock_client.select rs: true
            break unless rs
            data, who = sock_client.recv_nonblock
            sock_client.send Network::ACK, who
            packet.read data 
            break if data.empty? or data == Network::FIN
            if prev_packet && packet.num_packet != prev_packet.num_packet
              file.write packet.data
            end
            binding.pry
            prev_packet = packet.dup
          end
        end
      end
    end
  end
end