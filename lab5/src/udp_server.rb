require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'
require 'slop'
require 'pry'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

Network::DatagramSocket.listen opts do |socket|
  XIO::XFile.write opts do |file|
    loop do
      rs, = socket.select rs: true
      break unless rs

      data, who = socket.recv
      socket.send Network::ACK, who
      break if data.empty? or data == Network::FIN
      file.write data
    end
  end
end
