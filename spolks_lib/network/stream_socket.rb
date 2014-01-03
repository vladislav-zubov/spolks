require 'socket'
require_relative 'abstract_socket'

module Network
  class StreamSocket < AbstractSocket
    def initialize(sock_or_addr={})
      if sock_or_addr.instance_of?(Socket)
        @socket = sock_or_addr
      else
        @socket = Socket.new(Constants::AF_INET, Constants::SOCK_STREAM, 0)
        @socket.setsockopt(Constants::SOL_SOCKET, Constants::SO_REUSEADDR, true)
        @sockaddr = Socket.sockaddr_in(sock_or_addr[:port], sock_or_addr[:host])
      end
    end

    def self.open(addrinfo, &block)
      socket = StreamSocket.new(addrinfo)
      socket.connect
      yield socket
    ensure
      socket.close if socket
    end

    def fd
      @socket
    end

    def accept
      socket, sockaddr = @socket.accept
      [StreamSocket.new(socket), sockaddr]
    end

    def listen(count=3)
      @socket.listen(count)
    end

    def connect
      @socket.connect(@sockaddr)
    end

    def bind
      @socket.bind(@sockaddr)
    end

    def send(string)
      @socket.send(string, 0)
    end

    def send_oob(msg='i')
      @socket.send(msg, Socket::MSG_OOB)
      # sleep 1
    end

    def recv(size=Constants::CHUNK_SIZE)
      @socket.recv(size)
    end

    def recv_oob
      @socket.recv(15 ,Socket::MSG_OOB)
    end

    def select(descr={}, timeout=Constants::TIMEOUT)
      read_array = descr[:rs] ? [@socket] : []
      write_array = descr[:ws] ? [@socket] : []
      error_array = descr[:es] ? [@socket] : []


      rs, ws, es = IO.select(read_array, write_array, error_array, timeout)
      [rs ? rs.any? : false,
       rs ? ws.any? : false,
       es ? es.any? : false]
    end

    def close
      @socket.close
    end
  end
end





def create
    authorize! :create, @order
<<<<<<< Updated upstream
    @order.current_user = current_user
    if @order.account.logic == 'allstate'
      @order.wait_for_submit
    else
      @order.default_submit
    end
    if @order.save
=======
    results = []
    i = -1
    @orders.each do |order, index|
      if session[:results][i = i + 1]
        order.current_user = current_user
        if order.account.logic == 'allstate'
          order.wait_for_submit
        else
          order.default_submit
        end
        if results << order.save
          session.delete(:order)
          if @order.account.logic == 'allstate'
            flash[:notice] = "Thank you! Your UBI order was sent for agreement."
          else
            flash[:notice] = "Thank you! Your UBI order was submitted."
          end
        end
      end
    end
    if results.all? { |result| result == false }
      redirect_to action: 'confirmation'
    else
      redirect_to action: 'index'
    end
>>>>>>> Stashed changes
      session.delete(:order)
      if @order.account.logic == 'allstate'
        flash[:notice] = "Thank you! Your UBI order was sent for agreement."
      else
        flash[:notice] = "Thank you! Your UBI order was submitted."
      end
      redirect_to action: 'index'
    end
    #authorize! :create, @order
    #@order.current_user = current_user
    #if @order.save
    #  session.delete(:order)
    #  flash[:notice] = "Thank you! Your UBI order was submitted."
    #  redirect_to action: 'index'
    #else
    #  redirect_to action: 'confirmation'
    #end
  end