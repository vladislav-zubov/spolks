require 'slop'
require 'pry'
require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'

CHUNK_SIZE = 32768

%w(TERM INT).each do |signal|
  Signal.trap signal do
    exit
  end
end

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

def save_offset(file)
  File.open('offset', 'w+') do |file_offset|
    file_offset.write file.pos.to_s
  end
end

if opts.file?
  Network::StreamSocket.open opts do |sock|
    _, ws, = sock.select ws: true
    offset = nil
    File.open('offset', 'r+') do |file|
      offset = file.read CHUNK_SIZE
      offset ||= "0"
      sock.send offset
    end
    File.open(opts[:file], 'r') do |file|
      file.seek(offset.to_i)
      loop do
        chunk = file.read CHUNK_SIZE

        if chunk.nil?
          File.open( 'offset', 'w' ) { |file| file.truncate(0) }
          break
        end
        begin
          sock.send chunk unless chunk.nil?
        rescue Errno::ECONNRESET
          save_offset(file)
          exit
        rescue Errno::EPIPE
          save_offset(file)
          exit
        end
      end
    end
  end
end
