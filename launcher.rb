require_relative "server"

PORT = 5050

server = Server.new(PORT)
server.run