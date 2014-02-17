require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'pry'

class UdpServer

  @opts = nil

  def listen(opts)
    @opts = opts
    @socket = Network::DatagramSocket.listen(opts)
  end

  def connected_user
    new_thread
  end

  private

    def new_thread
      Thread.new do
        recieve_file
      end
    end

    def recieve_file
      packet = Network::Packet.new
      file_name, who = @socket.recv
      packet.read file_name
      file_name = packet.data
      file_size = File.size?(file_name) || 0
      packet_with_pos = Network::Packet.new num_packet: 0,len: file_size.to_s.length, data: file_size.to_s, inf_or_data: 3
      @socket.send packet_with_pos.to_binary_s, who
      prev_num_packet = nil
      sock_client = Network::DatagramSocket.new(host: @opts[:host], port: 0)
      sock_client.bind
      port = sock_client.get_port
      packet_with_port = Network::Packet.new num_packet: 0,len: port.to_s.length, data: port.to_s, inf_or_data: 3
      @socket.send packet_with_port.to_binary_s, who
      File.open(file_name, "a+") do |file|
        loop do
          rs, = sock_client.select rs: true
          break unless rs
          if rs
            data, who = sock_client.recv_nonblock
          end
          rs, ws = sock_client.select ws: true
          if ws
            sock_client.send Network::ACK, who
          end
          break if data.empty? or data == Network::FIN
          packet.read data
          if packet.num_packet != prev_num_packet
            file.write packet.data
          end
          prev_num_packet = packet.num_packet.dup
        end
      end
    end
end

