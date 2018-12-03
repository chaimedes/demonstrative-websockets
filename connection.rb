class Connection

  attr_reader :socket

  def initialize(socket)
	@socket = socket
  end


  # Receive and decode a message from the client.
  def recv
	
	# First byte indicates opcode, among other things
	op = socket.read(1).bytes[0]
	
	# Second byte includes masking flag and payload length indicator
	mask_plus_length = socket.read(1).bytes[0]

	# Purely the length indicator
	length = mask_plus_length - 128	

	# Determine how to read the message length
	# If length is under 125, length is just the existing length indicator, so there's nothing to do there.
	
	# If length is 126, the next two bytes form an unsigned 16-bit int of the payload length
	if length == 126
	  socket.read(2).unpack("n")[0]
	
	# If length is 127, the next eight bytes form an unsigned 64-bit int of the payload length
	else
	  socket.read(8).unpack("Q>")[0]
	end

	# Masking key randomly selected by the client. Server needs this to decode the content.
	keys = socket.read(4).bytes

	# The encoded content of the message
	encoded = socket.read(length).bytes

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

  
end

