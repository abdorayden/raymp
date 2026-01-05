#include <string.h>
#include <stdlib.h>
#include "../include/rmp_socket.h"

#if defined(_WIN32) || defined(_WIN64)
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "ws2_32.lib")
    typedef int socklen_t;
#else
    #include <sys/types.h>
    #include <sys/socket.h>
    #include <netinet/in.h>
    #include <netinet/tcp.h>
    #include <netinet/ip_icmp.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <unistd.h>
    #include <fcntl.h>
    #include <errno.h>
    typedef int SOCKET;
    #define INVALID_SOCKET -1
    #define SOCKET_ERROR -1
#endif

#define PROTO_TCP 0
#define PROTO_UDP 1
#define PROTO_ICMP 2
#define PROTO_RAW 3

#define RSOCKET_MT "RSocket"
#define BUFFER_SIZE 8192

struct RSocket {
    SOCKET sock;
    int is_open;
    int protocol;
};

#if defined(_WIN32) || defined(_WIN64)
static int winsock_init = 0;

static void init_winsock(void) {
    if (!winsock_init) {
        WSADATA wsa;
        WSAStartup(MAKEWORD(2, 2), &wsa);
        winsock_init = 1;
    }
}

static void close_socket(SOCKET s) {
    closesocket(s);
}

static int get_error(void) {
    return WSAGetLastError();
}

static int set_nonblocking(SOCKET s, int nb) {
    u_long mode = nb ? 1 : 0;
    return ioctlsocket(s, FIONBIO, &mode) == 0;
}
#else
static void init_winsock(void) {}

static void close_socket(SOCKET s) {
    close(s);
}

static int get_error(void) {
    return errno;
}

static int set_nonblocking(SOCKET s, int nb) {
    int flags = fcntl(s, F_GETFL, 0);
    if (flags == -1) return 0;
    flags = nb ? (flags | O_NONBLOCK) : (flags & ~O_NONBLOCK);
    return fcntl(s, F_SETFL, flags) == 0;
}
#endif

RSocket* rmp_socket_new(rmp_protocol_t protocol) {
    init_winsock();

    int sock_type = SOCK_STREAM;
    int sock_proto = 0;

    switch (protocol) {
        case RMP_PROTO_TCP:
            sock_type = SOCK_STREAM;
            sock_proto = IPPROTO_TCP;
            break;
        case RMP_PROTO_UDP:
            sock_type = SOCK_DGRAM;
            sock_proto = IPPROTO_UDP;
            break;
        case RMP_PROTO_ICMP:
            sock_type = SOCK_RAW;
            sock_proto = IPPROTO_ICMP;
            break;
        case RMP_PROTO_RAW:
            sock_type = SOCK_RAW;
            sock_proto = IPPROTO_RAW;
            break;
        default:
            return NULL;
    }

    SOCKET sock = socket(AF_INET, sock_type, sock_proto);
    if (sock == INVALID_SOCKET) {
        return NULL;
    }

    RSocket* rs = (RSocket*)malloc(sizeof(RSocket));
    if (!rs) {
        close_socket(sock);
        return NULL;
    }

    rs->sock = sock;
    rs->is_open = 1;
    rs->protocol = protocol;
    return rs;
}

bool rmp_socket_connect(RSocket* socket, const char* host, int port) {
    if (!socket || !host || !socket->is_open) {
        return false;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);

    if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
        struct hostent* he = gethostbyname(host);
        if (!he) {
            return false;
        }
        memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    }

    if (connect(socket->sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        return false;
    }

    return true;
}

bool rmp_socket_bind(RSocket* socket, const char* host, int port) {
    if (!socket || !host || !socket->is_open) {
        return false;
    }

    int reuse = 1;
    setsockopt(socket->sock, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, sizeof(reuse));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);

    if (strcmp(host, "*") == 0 || strcmp(host, "0.0.0.0") == 0) {
        addr.sin_addr.s_addr = INADDR_ANY;
    } else {
        if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
            return false;
        }
    }

    if (bind(socket->sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        return false;
    }

    return true;
}

bool rmp_socket_listen(RSocket* socket, int backlog) {
    if (!socket || !socket->is_open) {
        return false;
    }

    if (listen(socket->sock, backlog) == SOCKET_ERROR) {
        return false;
    }

    return true;
}

RSocket* rmp_socket_accept(RSocket* socket, char* client_ip, int client_ip_size, int* client_port) {
    if (!socket || !client_ip || !client_port || !socket->is_open) {
        return NULL;
    }

    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    SOCKET client_sock = accept(socket->sock, (struct sockaddr*)&client_addr, &addr_len);

    if (client_sock == INVALID_SOCKET) {
        return NULL;
    }

    RSocket* client_rs = (RSocket*)malloc(sizeof(RSocket));
    if (!client_rs) {
        close_socket(client_sock);
        return NULL;
    }

    client_rs->sock = client_sock;
    client_rs->is_open = 1;
    client_rs->protocol = RMP_PROTO_TCP; // Accepted sockets are always TCP

    inet_ntop(AF_INET, &client_addr.sin_addr, client_ip, client_ip_size);
    *client_port = ntohs(client_addr.sin_port);

    return client_rs;
}

int rmp_socket_send(RSocket* socket, const char* data, int len) {
    if (!socket || !data || !socket->is_open) {
        return -1;
    }

    int sent = send(socket->sock, data, len, 0);
    if (sent == SOCKET_ERROR) {
        return -1;
    }

    return sent;
}

int rmp_socket_recv(RSocket* socket, char* buffer, int buffer_size) {
    if (!socket || !buffer || !socket->is_open) {
        return -1;
    }

    if (buffer_size <= 0 || buffer_size > BUFFER_SIZE) {
        buffer_size = BUFFER_SIZE;
    }

    int received = recv(socket->sock, buffer, buffer_size, 0);

    if (received == 0) {
        return -1; // Connection closed
    }

    if (received == SOCKET_ERROR) {
        return -1;
    }

    return received;
}

int rmp_socket_sendto(RSocket* socket, const char* data, int len, const char* host, int port) {
    if (!socket || !data || !host || !socket->is_open) {
        return -1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);

    if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
        struct hostent* he = gethostbyname(host);
        if (!he) {
            return -1;
        }
        memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    }

    int sent = sendto(socket->sock, data, len, 0, (struct sockaddr*)&addr, sizeof(addr));
    if (sent == SOCKET_ERROR) {
        return -1;
    }

    return sent;
}

int rmp_socket_recvfrom(RSocket* socket, char* buffer, int buffer_size, char* from_ip, int from_ip_size, int* from_port) {
    if (!socket || !buffer || !from_ip || !from_port || !socket->is_open) {
        return -1;
    }

    if (buffer_size <= 0 || buffer_size > BUFFER_SIZE) {
        buffer_size = BUFFER_SIZE;
    }

    struct sockaddr_in from_addr;
    socklen_t from_len = sizeof(from_addr);

    int received = recvfrom(socket->sock, buffer, buffer_size, 0, (struct sockaddr*)&from_addr, &from_len);

    if (received == SOCKET_ERROR) {
        return -1;
    }

    inet_ntop(AF_INET, &from_addr.sin_addr, from_ip, from_ip_size);
    *from_port = ntohs(from_addr.sin_port);

    return received;
}

bool rmp_socket_close(RSocket* socket) {
    if (!socket) {
        return false;
    }

    if (socket->is_open) {
        close_socket(socket->sock);
        socket->is_open = 0;
    }

    free(socket);
    return true;
}

bool rmp_socket_setnonblock(RSocket* socket, bool nonblock) {
    if (!socket || !socket->is_open) {
        return false;
    }

    if (!set_nonblocking(socket->sock, nonblock)) {
        return false;
    }

    return true;
}

bool rmp_socket_setnodelay(RSocket* socket, bool nodelay) {
    if (!socket || !socket->is_open) {
        return false;
    }

    if (socket->protocol != RMP_PROTO_TCP) {
        return false;
    }

    if (setsockopt(socket->sock, IPPROTO_TCP, TCP_NODELAY, (const char*)&nodelay, sizeof(nodelay)) == SOCKET_ERROR) {
        return false;
    }

    return true;
}

bool rmp_socket_setbroadcast(RSocket* socket, bool broadcast) {
    if (!socket || !socket->is_open) {
        return false;
    }

    if (setsockopt(socket->sock, SOL_SOCKET, SO_BROADCAST, (const char*)&broadcast, sizeof(broadcast)) == SOCKET_ERROR) {
        return false;
    }

    return true;
}

rmp_protocol_t rmp_socket_getprotocol(RSocket* socket) {
    if (!socket) {
        return RMP_PROTO_TCP; // Default
    }

    switch (socket->protocol) {
        case RMP_PROTO_TCP:  return RMP_PROTO_TCP;
        case RMP_PROTO_UDP:  return RMP_PROTO_UDP;
        case RMP_PROTO_ICMP: return RMP_PROTO_ICMP;
        case RMP_PROTO_RAW:  return RMP_PROTO_RAW;
        default:             return RMP_PROTO_TCP;
    }
}