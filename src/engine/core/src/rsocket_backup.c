/****************************************************************************************/
/*  Copyright (c) 2025 Ray Den 								*/
/*  											*/ 
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
/*  of this software and associated documentation files (the "Software"), to deal 	*/
/*  in the Software without restriction, including without limitation the rights 	*/
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
/*  copies of the Software, and to permit persons to whom the Software is 		*/
/*  furnished to do so, subject to the following conditions: 				*/
/*  											*/ 
/*  The above copyright notice and this permission notice shall be included in 		*/
/*  all copies or substantial portions of the Software. 				*/
/*  											*/ 
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
/*  THE SOFTWARE. 									*/
/*  											*/ 
/****************************************************************************************/

#include "lua.h"
#include "lauxlib.h"
#include "simply.h"

#include <string.h>
#include <stdlib.h>

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
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <unistd.h>
    #include <fcntl.h>
    #include <errno.h>
    typedef int SOCKET;
    #define INVALID_SOCKET -1
    #define SOCKET_ERROR -1
#endif

#define RSOCKET_MT "RSocket"
#define BUFFER_SIZE 8192

typedef struct {
    SOCKET sock;
    int is_open;
} RSocket;

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
#else
static void init_winsock(void) {}

static void close_socket(SOCKET s) {
    close(s);
}

static int get_error(void) {
    return errno;
}
#endif

static RSocket* check_socket(STATE, int idx) {
    return (RSocket*)luaL_checkudata(L, idx, RSOCKET_MT);
}

ALWAYS_INT rsocket_new(STATE) {
    init_winsock();
    
    SOCKET sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == INVALID_SOCKET) {
        lua_pushnil(L);
        lua_pushfstring(L, "socket failed: %d", get_error());
        return 2;
    }

    RSocket* rs = (RSocket*)lua_newuserdata(L, sizeof(RSocket));
    rs->sock = sock;
    rs->is_open = 1;
    luaL_setmetatable(L, RSOCKET_MT);
    return 1;
}

ALWAYS_INT rsocket_connect(STATE) {
    RSocket* rs = check_socket(L, 1);
    const char* host = luaL_checkstring(L, 2);
    int port = luaL_checkinteger(L, 3);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "socket closed");
        return 2;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);

    if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
        struct hostent* he = gethostbyname(host);
        if (!he) {
            lua_pushnil(L);
            lua_pushstring(L, "host not found");
            return 2;
        }
        memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    }

    if (connect(rs->sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        lua_pushnil(L);
        lua_pushfstring(L, "connect failed: %d", get_error());
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_bind(STATE) {
    RSocket* rs = check_socket(L, 1);
    const char* host = luaL_checkstring(L, 2);
    int port = luaL_checkinteger(L, 3);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "socket closed");
        return 2;
    }

    int reuse = 1;
    setsockopt(rs->sock, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, sizeof(reuse));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)port);
    
    if (strcmp(host, "*") == 0 || strcmp(host, "0.0.0.0") == 0) {
        addr.sin_addr.s_addr = INADDR_ANY;
    } else {
        if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
            lua_pushnil(L);
            lua_pushstring(L, "invalid address");
            return 2;
        }
    }

    if (bind(rs->sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        lua_pushnil(L);
        lua_pushfstring(L, "bind failed: %d", get_error());
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    
    if (strcmp(host, "*") == 0 || strcmp(host, "0.0.0.0") == 0) {
        addr.sin_addr.s_addr = INADDR_ANY;
    } else {
        if (inet_pton(AF_INET, host, &addr.sin_addr) != 1) {
            lua_pushnil(L);
            lua_pushstring(L, "Invalid IP address");
            return 2;
        }
    }

    if (bind(rs->sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        lua_pushnil(L);
        lua_pushfstring(L, "Bind failed: error code %d", SOCKET_ERROR_CODE);
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_listen(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    int backlog = luaL_optinteger(L, 2, 5);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    if (listen(rs->sock, backlog) == SOCKET_ERROR) {
        lua_pushnil(L);
        lua_pushstring(L, "Listen failed");
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_accept(STATE) {
    RSocket* rs = check_rsocket(L, 1);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    SOCKET client_sock = accept(rs->sock, (struct sockaddr*)&client_addr, &addr_len);

    if (client_sock == INVALID_SOCKET) {
        if (WOULD_BLOCK) {
            lua_pushnil(L);
            return 1;
        }
        lua_pushnil(L);
        lua_pushstring(L, "Accept failed");
        return 2;
    }

    RSocket* client = (RSocket*)lua_newuserdata(L, sizeof(RSocket));
    client->sock = client_sock;
    client->is_open = 1;
    luaL_setmetatable(L, RSOCKET_MT);

    char ip[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &client_addr.sin_addr, ip, sizeof(ip));
    lua_pushstring(L, ip);
    lua_pushinteger(L, ntohs(client_addr.sin_port));

    return 3;
}

ALWAYS_INT rsocket_send(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    size_t len;
    const char* data = luaL_checklstring(L, 2, &len);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    int sent = send(rs->sock, data, (int)len, 0);
    if (sent == SOCKET_ERROR) {
        if (WOULD_BLOCK) {
            lua_pushinteger(L, 0);
            return 1;
        }
        lua_pushnil(L);
        lua_pushstring(L, "Send failed");
        return 2;
    }

    lua_pushinteger(L, sent);
    return 1;
}

ALWAYS_INT rsocket_recv(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    int size = luaL_optinteger(L, 2, BUFFER_SIZE);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    if (size <= 0 || size > BUFFER_SIZE) {
        size = BUFFER_SIZE;
    }

    char buffer[BUFFER_SIZE];
    int received = recv(rs->sock, buffer, size, 0);

    if (received == 0) {
        lua_pushnil(L);
        lua_pushstring(L, "Connection closed");
        return 2;
    }

    if (received == SOCKET_ERROR) {
        if (WOULD_BLOCK) {
            lua_pushnil(L);
            return 1;
        }
        lua_pushnil(L);
        lua_pushstring(L, "Receive failed");
        return 2;
    }

    lua_pushlstring(L, buffer, received);
    return 1;
}

ALWAYS_INT rsocket_close(STATE) {
    RSocket* rs = check_rsocket(L, 1);

    if (rs->is_open) {
        CLOSE_SOCKET(rs->sock);
        rs->is_open = 0;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_setblocking(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    int blocking = lua_toboolean(L, 2);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    if (!set_nonblocking(rs->sock, !blocking)) {
        lua_pushnil(L);
        lua_pushstring(L, "Failed to set blocking mode");
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_setnodelay(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    int nodelay = lua_toboolean(L, 2);

    if (!rs->is_open) {
        lua_pushnil(L);
        lua_pushstring(L, "Socket is closed");
        return 2;
    }

    if (setsockopt(rs->sock, IPPROTO_TCP, TCP_NODELAY, (const char*)&nodelay, sizeof(nodelay)) == SOCKET_ERROR) {
        lua_pushnil(L);
        lua_pushstring(L, "Failed to set TCP_NODELAY");
        return 2;
    }

    lua_pushboolean(L, 1);
    return 1;
}

ALWAYS_INT rsocket_gc(STATE) {
    RSocket* rs = (RSocket*)lua_touserdata(L, 1);
    if (rs && rs->is_open) {
        CLOSE_SOCKET(rs->sock);
        rs->is_open = 0;
    }
    return 0;
}

ALWAYS_INT rsocket_tostring(STATE) {
    RSocket* rs = check_rsocket(L, 1);
    lua_pushfstring(L, "RSocket: %s", rs->is_open ? "open" : "closed");
    return 1;
}

static const luaL_Reg rsocket_methods[] = {
    {"connect", rsocket_connect},
    {"bind", rsocket_bind},
    {"listen", rsocket_listen},
    {"accept", rsocket_accept},
    {"send", rsocket_send},
    {"recv", rsocket_recv},
    {"close", rsocket_close},
    {"setblocking", rsocket_setblocking},
    {"setnodelay", rsocket_setnodelay},
    {NULL, NULL}
};

static const luaL_Reg rsocket_meta[] = {
    {"__gc", rsocket_gc},
    {"__tostring", rsocket_tostring},
    {NULL, NULL}
};

static const luaL_Reg lib[] = {
    {"tcp", rsocket_tcp},
    {NULL, NULL}
};

int luaopen_rmp_rsocket(STATE) {
    luaL_newmetatable(L, RSOCKET_MT);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, rsocket_methods, 0);
    luaL_setfuncs(L, rsocket_meta, 0);
    lua_pop(L, 1);

    luaL_newlib(L, lib);
    return 1;
}

