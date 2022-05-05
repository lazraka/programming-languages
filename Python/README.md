# Proxy herd with asyncio

Your prototype should consist of five servers (with server IDs 'Riley', 'Jaquez', 'Juzang', 'Campbell', 'Bernard') that communicate to each other (bidirectionally) with the following pattern:

Riley talks with Jaquez and Juzang.
Bernard talks with everyone else but Riley.
Juzang talks with Campbell.

Each server should accept TCP connections from clients that emulate mobile devices with IP addresses and DNS names.

The server should respond to clients with a message using this format:

AT Riley +0.263873386 kiwi.cs.ucla.edu +34.068930-118.445127 1621464827.959498503

Clients can also query for information about places near other clients' locations, with a query using this format:

WHATSAT kiwi.cs.ucla.edu 10 5

The server responds with a AT message in the same format as before, giving the most recent location reported by the client, along with the server that it talked to and the time the server did the talking.
Servers should respond to invalid commands with a line that contains a question mark (?), a space, and then a copy of the invalid command.

Servers communicate to each other too, using AT messages (or some variant of your design) to implement a simple flooding algorithm to propagate location updates to each other. Servers should not propagate place information to each other, only locations; when asked for place information, a server should contact Google Places directly for it. Servers should continue to operate if their neighboring servers go down, that is, drop a connection and then reopen a connection later.

Each server should log its input and output into a file, using a format of your design. The logs should also contain notices of new and dropped connections from other servers.
