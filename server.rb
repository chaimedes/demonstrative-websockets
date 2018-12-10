require 'socket'
require 'digest/sha1'
require 'base64'
require_relative 'connection.rb'

class Server

  # Start up the server
  def initialize(options={path: '/', port: 5555, host: '127.0.0.1'})
	@path, port, host = options[:path], options[:port], options[:host]
	@server = TCPServer.new(host, port)
  end

  # Allow a new connection
  def accept
	socket = @server.accept
	send_handshake(socket) && Connection.new(socket)
  end

  private

  # GUID for websocket protocol (https://tools.ietf.org/html/rfc6455#page-60)
  WS_MAGIC_STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


  # Attempt to send an initializing handshake.
  # This will only work if the socket has received a valid header.
  def send_handshake(socket)

	# Get the first line when available
	request_line = socket.gets

	# Get the header from the line read
	header = get_header(socket)

	# Attempt to parse the request line
	# We aren't going to pay attention to the header fields in the request
  	if (request_line =~ /GET #{@path} HTTP\/1.1/) && (header =~ /Sec-WebSocket-Key: (.*)\r\n/)
	  	
	  	# Create and return the initializing acceptance handshale
	  	ws_accept = create_websocket_accept($1)
		send_handshake_response(socket, ws_accept)

		# Let the handling class know everything went ok.
		return true

	end

	# If we failed to parse the header, return a 400.
	send_400(socket)

	# Let the handling class know we encountered an issue.
	false

  end # End of send_handshake(1)
 

  # Send back a 400 response to the socket.
  # Also close the connection
  def send_400(socket)
	socket << "HTTP/1.1 400 Bad Request\r\n" +
	  "Content-Type: text/pain\r\n" + 
	  "Connection: close\r\n" +
	  "\r\n" +
	  "Incorrect request"
	socket.close
  end

  # Send back the full acceptance connection response to the socket.
  def send_handshake_response(socket, ws_accept)
	socket << "HTTP/1.1 101 Switching Protocols\r\n" +
	"Upgrade: websocket\r\n" +
	"Connection: Upgrade\r\n" +
	"Sec-WebSocket-Accept: #{ws_accept}\r\n"
  end

  # Create the accept header from the key provided.
  def create_websocket_accept(key)
	digest = Digest::SHA1.digest(key + WS_MAGIC_STRING)
	Base64.encode64(digest)
  end

  # Attempt to read the actual header line.
  def get_header(socket, header = "")
	(line = socket.gets) == "\r\n" ? header : get_header(socket, header + line)
  end

end
