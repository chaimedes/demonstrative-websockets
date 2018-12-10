require 'logger'

class Connection

  attr_reader :socket

  # Accept a TCP socket and create a connection
  def initialize(socket)
	@socket = socket
	@logger = Logger.new(STDOUT)
	@logger.level = Logger::DEBUG # For learning
	@fin = nil
  end

  # Close this connection
  def close
	@logger.info("Closing the socket.")
	@logger.close
	@socket.shutdown(:RDWR)
	@socket.close
  end

  # Receive and decode a message from the client.
  def recv
	
	# What operation does the client want to perform?
	op = nil

	# First byte indicates opcode, among other things
	first_byte = socket.read(1).bytes[0]

	# If the first bit is on, this frame is final.
	# I.e. Any following frames are separate messages.
	if first_byte > 127
	  @fin = 1
	  op = first_byte - 128
	else
	  @fin = 0
	  op = first_byte
	end

	@logger.debug("Received op code %d" % op)
	@logger.debug("(Hex code %x)" % op.to_s(16))
	
	# If we got a 0x8 close op code, shut down.
	if op == 8
	  send_close # Confirm for the client
	  close # Close the socket
	  return false # Let the server know
	end

	# Second byte includes masking flag and payload length indicator
	mask_plus_length = socket.read(1).bytes[0]
	
	# Purely the length indicator
	length = mask_plus_length - 128	

	# Determine how to read the message length
	# If length is under 125, length is just the existing length indicator, so there's nothing to do there.
	
	# If length is 126, the next two bytes form an unsigned 16-bit int of the payload length
	if length == 126
	  length = socket.read(2).unpack("n")[0]
	
	# If length is 127, the next eight bytes form an unsigned 64-bit int of the payload length
	elsif length == 127
	  length = socket.read(8).unpack("Q>")[0]
	end
	
	# Masking key randomly selected by the client. Server needs this to decode the content.
	keys = socket.read(4).bytes
	
	# The encoded content of the message
	encoded = socket.read(length).bytes
	
	# If we got a 0x9 ping op code, send a pong.
	if op == 9
	  send_pong(length, encoded)
	  return true
	end

	# Decode each byte against its corresponding key.
	decoded = encoded.each_with_index.map do |byte, index|
	  byte ^ keys[index % 4]
	end

	# Pack all decoded message bytes back into a string as 8-bit signed characters.
	decoded.pack("c*")
 
  end # End of recv


  # Send a message to the client
  # Server-to-client is unmasked.
  def send(message)

	@logger.info("Sending message.")

	# Indicate text content
	bytes = [129]

	# Figure the size of the message in bytes.
	size = message.bytesize

	# Now we put together the size section, following in reverse the same frame process as receiving.
	# If 125 or under, just append it
	if size <= 125
		bytes += [size]

	# If size is within two bytes, append 126 and the size converted in an unsigned 16-bit int
	elsif size < 2**16
		bytes += [126] + [size].pack("n").bytes

	# Otherwise use 127 and size as an unsigned 64-bit int
	else
		bytes += [127] + [size].pack("Q>").bytes
	end

	# Tack on the message content itself (the payload)
	bytes += message.bytes

	# Pack the data into a string and send it through the socket.
	data = bytes.pack("C*")
	socket << data

  end # End of send


  # Send a frame to the client containing a close code, to confirm the disconnect.
  def send_close

	@logger.info("Sending close frame.") 

	# 0x8 == close code
	bytes = [136]

	# No actual content
	bytes += [0]

	# Pack the data into a string and send it through the socket.
	data = bytes.pack("C*")
	socket << data

  end # End of send_close
  
  # Initiate a ping
  def ping

	@logger.info("Pinging client.")

	# 0x9 == ping code
	bytes = [137]

	# No need to provide a payload (but you could if you wanted)
	bytes += [0]

	# Pack the data into a string and send it through the socket.
	data = bytes.pack("C*")
	socket << data

  end # End of send_ping
  
  # Respond to a ping
  def pong(size, payload)

	@logger.info("Responding to ping.")

	# 0xA == pong code
	bytes = [138]

	# Now we put together the size section, following in reverse the same frame process as receiving.
	# If 125 or under, just append it
	if size <= 125
		bytes += [size]

	# If size is within two bytes, append 126 and the size converted in an unsigned 16-bit int
	elsif size < 2**16
		bytes += [126] + [size].pack("n").bytes

	# Otherwise use 127 and size as an unsigned 64-bit int
	else
		bytes += [127] + [size].pack("Q>").bytes
	end

	# Payload must be returned as received.
	bytes += payload.bytes

	# Pack the data into a string and send it through the socket.
	data = bytes.pack("C*")
	socket << data

  end # End of send_pong
  
end # End of Connection

