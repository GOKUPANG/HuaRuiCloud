/*
 Copyright (c) <2014>, skysent
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. All advertising materials mentioning features or use of this software
 must display the following acknowledgement:
 This product includes software developed by skysent.
 4. Neither the name of the skysent nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY skysent ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL skysent BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <string.h>
#include <unistd.h>
#include <netdb.h>
#include <errno.h>
#define yudpsocket_buff_len 8192

//return socket fd
int yudpsocket_server(int port){
    //create socket
    int socketfd=socket(AF_INET, SOCK_DGRAM, 0);
    int enable   = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(enable) );
    setsockopt( socketfd, SOL_SOCKET, SO_BROADCAST, &enable, sizeof(enable) );
    //bind
    struct sockaddr_in serv_addr;
    memset( &serv_addr, '\0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(port);
    int r=bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
    if(r==0){
        return socketfd;
    }else{
        return -1;
    }
}
int yudpsocket_recive(int socket_fd,char *outdata,int expted_len,char *remoteip,int* remoteport){
    struct sockaddr_in  cli_addr;
    socklen_t clilen=sizeof(cli_addr);
    memset(&cli_addr, 0x0, sizeof(struct sockaddr_in));
    int len=(int)recvfrom(socket_fd, outdata, expted_len, 0, (struct sockaddr *)&cli_addr, &clilen);
    char *clientip=inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport=cli_addr.sin_port;
    if (len < 0) {
        return -errno;
    }
    return len;
}
int yudpsocket_close(int socket_fd){
    return close(socket_fd);
}
//return socket fd
int yudpsocket_client(){
    //create socket
    int socketfd=socket(AF_INET, SOCK_DGRAM, 0);
    int enable   = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(enable) );
    setsockopt( socketfd, SOL_SOCKET, SO_BROADCAST, &enable, sizeof(enable) );
    return socketfd;
}
int yudpsocket_get_server_ip(char *host,char *ip){
    struct hostent *hp;
    struct sockaddr_in addr;
    hp = gethostbyname(host);
    if(hp==NULL){
        return -1;
    }
    bcopy((char *)hp->h_addr, (char *)&addr.sin_addr, hp->h_length);
    char *clientip=inet_ntoa(addr.sin_addr);
    memcpy(ip, clientip, strlen(clientip));
    return 0;
}
//send message to addr and port
int yudpsocket_sentto(int socket_fd,char *msg,int len, char *toaddr, int topotr){
    struct sockaddr_in addr;
    socklen_t addrlen=sizeof(addr);
    memset(&addr, 0x0, sizeof(struct sockaddr_in));
    addr.sin_family=AF_INET;
    addr.sin_port=htons(topotr);
    addr.sin_addr.s_addr=inet_addr(toaddr);
    int sendlen=(int)sendto(socket_fd, msg, len, 0, (struct sockaddr *)&addr, addrlen);
    return sendlen;
}

int setRcvTimeout(int fd, int mils){
    struct timeval val;
    memset(&val, 0x0, sizeof(val));
    val.tv_sec = mils / 1000;
    val.tv_usec = (mils % 1000) * 1000;
    int ret = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &val, sizeof(val) );
    if (ret != 0) {
        return -errno;
    }
    return ret;
}


