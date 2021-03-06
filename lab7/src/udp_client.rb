require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'slop'
require 'pry'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

CHUNK_SIZE = 32768
sent = true
count = 0

port = nil
pos = nil

packet = Network::Packet.new

Network::DatagramSocket.open opts do |socket|
  file_string = opts[:file].to_s
  file_and_pos = Network::Packet.new num_packet: count,len: file_string.length, data: file_string, inf_or_data: 1
  count = count + 1
  socket.send file_and_pos.to_binary_s
  rs, = socket.select rs: true
  packet_with_pos, who = socket.recv_nonblock
  packet.read packet_with_pos
  pos = packet.data.dup
  rs = nil
  ws = nil
  rs, ws, = socket.select rs: true
  port, = socket.recv
  packet.read port
  port = packet.data
end

Network::DatagramSocket.open({ host: opts[:host], port: port }) do |socket|
  File.open(opts[:file], 'r') do |file|
    if file.seek(pos.to_i) < 0
      exit
    end
    loop do
      chunk = file.read CHUNK_SIZE
      break unless chunk
      rs, ws, = socket.select ws: true
      if ws
        msg = Network::Packet.new num_packet: count,len: chunk.length, data: chunk, inf_or_data: 0
        socket.send msg.to_binary_s
        count = 0 if count == 9
        count = count + 1
        loop do
          rs, ws, = socket.select rs: true
          if rs
            msg, = socket.recv
            break
          else
            socket.send msg.to_binary_s
          end
        end
      end
    end
  end
  socket.send Network::FIN
end

