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

Network::DatagramSocket.open opts do |socket|
  rs = nil
  ws = nil
  XIO::XFile.read opts do |file, chunk|
    if chunk.size < CHUNK_SIZE
      binding.pry
    end
    rs, ws, = socket.select ws: true
    if ws
      socket.send count.to_s + chunk
      count = 0 if count == 9
      count = count + 1
      loop do
        rs, ws, = socket.select rs: true
        if rs
          msg, = socket.recv
          break
        else
          socket.send chunk
        end
      end
    end
  end
  socket.send Network::FIN
end
