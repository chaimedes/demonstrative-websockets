require_relative 'server.rb'
server = Server.new

puts "Waiting for connections."

# Run the server until actively terminated
loop do

  # Open a thread on the socket provided by any new connection
  Thread.new(server.accept) do |connection|
	
	puts "Connected"
	
	# Continue until told to close by the client.
	while ((message = connection.recv))
	  puts "Message recieved."
	  connection.send("Server has received your message.")
	end

	puts "Disconnected"
  
  end # End of thread

end # End of looping
