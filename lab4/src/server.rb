require 'slop'
require 'pry'
require_relative '../../spolks_lib/network'
require_relative '../../spolks_lib/file'

opts = Slop.parse(help: true) do
  on :g, :host=, 'Hostname'
  on :p, :port=, 'Port'
  on :v, :verbose, 'Enable verbose mode'
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
          rs, _, es = client.select rs: true, es: true

          unless rs or es
            client.close
            break
          end
          if es
            client.recv_oob
            puts file.pos.to_s
          end
          
          chunk = client.recv
          break if chunk.empty?
          file.write chunk
        end
      end
    end
  end
end