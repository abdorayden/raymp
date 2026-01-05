#ifndef RMP_SOCKET_H_
#define RMP_SOCKET_H_

#include <stdbool.h>

// Socket API functions

typedef enum {
    RMP_PROTO_TCP,
    RMP_PROTO_UDP,
    RMP_PROTO_ICMP,
    RMP_PROTO_RAW
} rmp_protocol_t;

typedef struct RSocket RSocket;

/**
 * Create a new socket
 * @param protocol: protocol type (TCP, UDP, etc.)
 * @return: pointer to new socket, or NULL on failure
 */
RSocket* rmp_socket_new(rmp_protocol_t protocol);

/**
 * Connect a socket to a host and port
 * @param socket: socket to connect
 * @param host: host to connect to
 * @param port: port to connect to
 * @return: true on success, false on failure
 */
bool rmp_socket_connect(RSocket* socket, const char* host, int port);

/**
 * Bind a socket to a host and port
 * @param socket: socket to bind
 * @param host: host to bind to
 * @param port: port to bind to
 * @return: true on success, false on failure
 */
bool rmp_socket_bind(RSocket* socket, const char* host, int port);

/**
 * Listen on a socket (for TCP)
 * @param socket: socket to listen on
 * @param backlog: maximum number of pending connections
 * @return: true on success, false on failure
 */
bool rmp_socket_listen(RSocket* socket, int backlog);

/**
 * Accept a connection on a socket (for TCP)
 * @param socket: socket to accept on
 * @param[out] client_ip: buffer to store client IP address
 * @param client_ip_size: size of client IP buffer
 * @param[out] client_port: pointer to store client port
 * @return: pointer to new client socket, or NULL on failure
 */
RSocket* rmp_socket_accept(RSocket* socket, char* client_ip, int client_ip_size, int* client_port);

/**
 * Send data through a socket
 * @param socket: socket to send through
 * @param data: data to send
 * @param len: length of data to send
 * @return: number of bytes sent, or -1 on failure
 */
int rmp_socket_send(RSocket* socket, const char* data, int len);

/**
 * Receive data from a socket
 * @param socket: socket to receive from
 * @param buffer: buffer to store received data
 * @param buffer_size: size of the buffer
 * @return: number of bytes received, or -1 on failure
 */
int rmp_socket_recv(RSocket* socket, char* buffer, int buffer_size);

/**
 * Send data to a specific address (for UDP)
 * @param socket: socket to send through
 * @param data: data to send
 * @param len: length of data to send
 * @param host: destination host
 * @param port: destination port
 * @return: number of bytes sent, or -1 on failure
 */
int rmp_socket_sendto(RSocket* socket, const char* data, int len, const char* host, int port);

/**
 * Receive data from a specific address (for UDP)
 * @param socket: socket to receive from
 * @param buffer: buffer to store received data
 * @param buffer_size: size of the buffer
 * @param[out] from_ip: buffer to store sender IP address
 * @param from_ip_size: size of sender IP buffer
 * @param[out] from_port: pointer to store sender port
 * @return: number of bytes received, or -1 on failure
 */
int rmp_socket_recvfrom(RSocket* socket, char* buffer, int buffer_size, char* from_ip, int from_ip_size, int* from_port);

/**
 * Close a socket
 * @param socket: socket to close
 * @return: true on success, false on failure
 */
bool rmp_socket_close(RSocket* socket);

/**
 * Set socket to non-blocking mode
 * @param socket: socket to modify
 * @param nonblock: true to enable non-blocking, false to disable
 * @return: true on success, false on failure
 */
bool rmp_socket_setnonblock(RSocket* socket, bool nonblock);

/**
 * Set TCP_NODELAY option (disable Nagle's algorithm)
 * @param socket: socket to modify
 * @param nodelay: true to enable nodelay, false to disable
 * @return: true on success, false on failure
 */
bool rmp_socket_setnodelay(RSocket* socket, bool nodelay);

/**
 * Set SO_BROADCAST option
 * @param socket: socket to modify
 * @param broadcast: true to enable broadcast, false to disable
 * @return: true on success, false on failure
 */
bool rmp_socket_setbroadcast(RSocket* socket, bool broadcast);

/**
 * Get the protocol type of a socket
 * @param socket: socket to query
 * @return: protocol type
 */
rmp_protocol_t rmp_socket_getprotocol(RSocket* socket);

#endif // RMP_SOCKET_H_