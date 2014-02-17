require 'pry'
require_relative '../../spolks_lib/network/'
require_relative '../../spolks_lib/file'

class TcpServer

  def listen(opts)
    @socket = Network::StreamSocket.new(port: opts[:port], host: opts[:host])
    @socket.bind
    @socket.listen
    @socket
  end

  def connected_user
    client, = @socket.accept
    new_thread(client)
  end

  private

    def new_thread(client)
      Thread.new do
        recieve_file(client)
      end
    end

    def recieve_file(client)
      rs, = client.select rs: true
      file_name = client.recv

      XIO::XFile.write( { file: file_name } ) do |file|
        file.seek(IO::SEEK_END)
        rs, ws = client.select ws: true
        client.send file.size.to_s
        loop do
          rs, _, es = client.select rs: true, es: true

          unless rs or es
            client.close
            break
          end
          if es
            client.recv_oob
          end

          chunk = client.recv
          break if chunk.empty?
          file.write chunk
        end
      end
    end
end
