require_relative 'server.rb'
server = Server.new

# Run the server until actively terminated
loop do

  # Open a thread on the socket provided by any new connection
  Thread.new(server.accept) do |connection|
	
	puts "Connected"
	
	# Continue until told to close by the client.
	while ((message = connection.recv) != "close")
	  puts "Recieved: #{message}"
	  connection.send("Received #{message}.")
	end

	puts "Disconnected"
  
  end # End of thread

end # End of looping
