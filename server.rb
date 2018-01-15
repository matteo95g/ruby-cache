require 'socket'
require_relative "controller"

class Server

  def initialize(port)
    @server = TCPServer.open(port)
  end

  def run    
    loop do
      Thread.start(@server.accept) do |conn| 
        controller = Controller.new
        loop do
          controller.do_command(conn)
        end
      end
    end
  end

end