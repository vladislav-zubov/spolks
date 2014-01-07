require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'slop'
require 'pry'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

prev_data = nil

Network::DatagramSocket.listen opts do |socket|
  XIO::XFile.write opts do |file|
    loop do
      rs, = socket.select rs: true
      break unless rs

      data, who = socket.recv
      socket.send Network::ACK, who
      break if data.empty? or data == Network::FIN
      if prev_data && data[0] != prev_data[0]
        data[0] = ''
        file.write data
      end
      prev_data = data
    end
  end
end
