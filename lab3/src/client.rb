require 'slop'
require 'pry'
require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'

CHUNK_SIZE = 32768

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

# if opts.file?
#   Network::StreamSocket.open opts do |sock|
#     _, ws, = sock.select ws: true
#     offset = nil
#     File.open('offset', 'r+') do |file|
#       offset = file.read CHUNK_SIZE
#       offset ||= "0"
#       sock.send offset
#     end
#     File.open(opts[:file], 'r') do |file|
#       file.seek(offset.to_i)
#       loop do 
#         chunk = file.read CHUNK_SIZE
        
#         if chunk.nil?
#           File.open( 'offset', 'w' ) { |file| file.truncate(0) }
#           break
#         end
#         begin
#           sock.send chunk unless chunk.nil?
#         rescue
#           File.open('offset', 'w+') do |file_offset|
#             file_offset.write file.pos.to_s
#             exit
#           end
#         end
#       end
#     end
#   end
# else
#   puts opts
# end

class Client
  
  def file_transfer(opts)
    Network::StreamSocket.open opts do |sock|
      _, ws, = sock.select ws: true
      offset = read_offset
      sock.send offset
      File.open(opts[:file], 'r') do |file|
        file.seek(offset.to_i)
        loop do 
          chunk = file.read CHUNK_SIZE
          if chunk.nil?
            clear_offset
            break
          end
          break if send_chunk(chunk)
        end
      end
    end
  end

  def send_chunk(chunk)
    begin
      sock.send chunk unless chunk.nil?
      true
    rescue
      save_offset
      false
    end
  end

  def read_offset
    offset = nil
    File.open('offset', 'r+') do |file|
      offset = file.read CHUNK_SIZE
      offset ||= "0"
    end
    offset
  end

  def clear_offset
    File.open( 'offset', 'w' ) { |file| file.truncate(0) }
  end

  def save_offset(pos)
    File.open('offset', 'w+') do |file_offset|
      file_offset.write pos
    end
  end
end

client = Client.new
client.file_transfer(opts)
