# Minimal WebSockets Server
*Derived from [https://blog.pusher.com/websockets-from-scratch/](https://blog.pusher.com/websockets-from-scratch/)*

This code implements an extremely minimal WebSockets server in Ruby, along with a browser client which can be used to connect to and test the server. 

![Demonstration of websocket implementation](http://mberlove.com/media/ws.gif)

Though relatively straightfoward to use, the process by which WebSockets operate can appear daunting and unintuitive. The server implemented here lays out line by line the process by which the server accepts, processes, and responds to WebSocket connections, peppered with running commentary.

I make no guarantees that the code is entirely correct, or that its performance and organization will meet everyone's standards, merely that the code works, and (as matters most in this case) complies with the RCF WebSockets specification in its primary requirements (some exceptions are described below). Hopefully this code will serve as a tool for learning, as WebSockets can be enjoyable to work with and learn about (assuming you enjoy code and networking).

Some aspects of the server are only partially implemented, mostly elements not strictly needed for the most basic implementation but "prepped" so they can be easily extended and applied. One example of this is the `fin` code flag, an instance variable of the connection which tracks the finbit of the frame. Currently unused, this variable can be leveraged to track messages across multiple frames.

Other stubs include the following:
- Pinging: the server responds to a ping from the client ("pong"). Ideally the ping-pong exchange should operate both ways; pinging the endpoint(s) relies on the clients more. The server as-is will never initiate a ping of its own. There is however a ping method which can be called, and it will be up to the client to respond appropriately.
- Non-text messaging: the server may accept messages which consist of non-textual data; currently, this code makes an assumption that the data is textual in nature, but manages the payload in such a way that it requires minimal effort to adjust how this data is processed.

A few features typical to websocket servers have been selectively excluded from implementation as described here:
- Subprotocols: the `Sec-WebSocket-Protocol` field in an initial handshake from the client requires the server to respond in kind, and the connection should then ideally operate in the selected manner. 
- Sec-WebSocket-Version: clients may request using a specific version of the protocol, to which the server responds with which version(s) it is willing to use.
- Unmasked requests: when a server recieves an unmasked frame from a client, it should terminate the connection.
- Extensions: the client may request extended capabilities in its initial handshake request (this is not a strict requirement to which the server must comply). 
- Failure rules: under certain conditions the server must fail the connection with a client.
- Data validation: the server is expected to validate all data (this applies to the client as well).
- URI syntax: certain rules apply to URI encoding which expect to be enforced.

As discussed, this server is intended to perform the primary duties of a websocket server with minimal code and minimal complication. It is intended to serve only as an example for learning and practice, or a basis upon which to build a more compliant server. 

## Get Started
To start up the server, run `ruby serve.rb` from a terminal. Connect to the server by loading up `index.html` in a browser or connecting via another local client. Note that this code was tested with Ruby v2.2.7.

## Reading List
WebSockets are fun to play around with, but it helps to uderstand the basics. Below, find a few links that might help familiarize yourself with the concepts.
- [MDN WebSockets API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
- [Introduction to WebSockets](https://www.linode.com/docs/development/introduction-to-websockets/)
- [WebSockets Specification](https://tools.ietf.org/html/rfc6455)
- [Writing WebSocket Servers (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers)
- [Writing WebSocket Client Applications (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications)
