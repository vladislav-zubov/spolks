require 'slop'
require 'pry'
require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :f, :file=, 'Filename'
end

if opts.file?
  Network::StreamServer.listen opts do |server|
    loop do
      client, = server.accept
      rs, = client.select rs: true
      offset = client.recv
      puts offset

      XIO::XFile.write opts do |file|
        file.seek(offset.to_i)
        loop do
          rs, = client.select rs: true
          unless rs
            client.close
            break
          end
          chunk = client.recv
          if chunk.empty?
            client.close
          end
          file.write chunk
        end
      end
    end
  end
end