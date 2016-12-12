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
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#include <sys/stat.h>
#include <dirent.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

#define CopyString(temp) (temp != NULL)? strdup(temp):NULL
const char* getIPV6(const char * mHost) {
    if(mHost == NULL)
        return NULL;
    struct addrinfo* res0;
    struct addrinfo hints;
    struct addrinfo* res;
    
    memset(&hints, 0, sizeof(hints));
    
    hints.ai_flags = AI_DEFAULT;// wjj modify
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    int n;
    if((n = getaddrinfo(mHost, "http", &hints, &res0)) != 0)
    {
        printf("getaddrinfo failed %d", n);
        return NULL;
    }
    
    struct sockaddr_in6* addr6;
    struct sockaddr_in * addr;
    const char* pszTemp;
    
    for(res = res0; res; res = res->ai_next)
    {
        char buf[32];
        if(res->ai_family == AF_INET6)
        {
            addr6 = (struct sockaddr_in6*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET6, &addr6->sin6_addr, buf, sizeof(buf));
        }
        else
        {
            addr = (struct sockaddr_in*)res->ai_addr;
            pszTemp = inet_ntop(AF_INET, &addr->sin_addr, buf, sizeof(buf));
        }
        
        break;
    }
    
    freeaddrinfo(res0);
    printf("**************getaddrinfo ok %s\n", pszTemp);
    return CopyString(pszTemp);
}



size_t get_error_str(char* err_str) {
	strcpy(err_str, strerror(errno));
	return strlen(err_str);
}

void ytcpsocket_set_block(int socket,int on) {
    int flags;
    flags = fcntl(socket,F_GETFL,0);
    if (on==0) {
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    }else{
        flags &= ~ O_NONBLOCK;
        fcntl(socket, F_SETFL, flags);
    }
}
int ytcpsocket_connect(const char *host,int port,int timeout){
    struct sockaddr_in sa;
    struct hostent *hp;
    int sockfd = -1;
    
    const char *addr=getIPV6(host);
    if(strchr(addr, ':') != NULL)
    {
        // ipv6
        if ((sockfd = socket(AF_INET6, SOCK_STREAM, 0)) < 0) {      // IPv6
            perror("Socket");
            exit(errno);
        }
        printf("socket created\n");
        struct sockaddr_in6 dest;      // IPv6
        /* 初始化服务器端（对方）的地址和端口信息 */
        bzero(&dest, sizeof(dest));
        dest.sin6_family = AF_INET6;     // IPv6
        dest.sin6_port = htons(port);     // IPv6
        /* if (inet_aton(argv[1], (struct in_addr *) &dest.sin_addr.s_addr) == 0) { */ // IPv4
        if ( inet_pton(AF_INET6, addr, &dest.sin6_addr) < 0 ) {                 // IPv6
            perror("inet_pton fail...");
            exit(errno);
        }
        printf("address created\n");
        /* 连接服务器 */
        if(connect(sockfd, (struct sockaddr *) &dest, sizeof(dest)) != 0) {
            perror("Connect ");
            exit(errno);
        }
        printf("server connected\n");
        ytcpsocket_set_block(sockfd,0);

    }
    else
    {
        hp = gethostbyname(host);
        if(hp==NULL){
            return -1;
        }
        bcopy((char *)hp->h_addr, (char *)&sa.sin_addr, hp->h_length);
        sa.sin_family = hp->h_addrtype;
        sa.sin_port = htons(port);
        sockfd = socket(hp->h_addrtype, SOCK_STREAM, 0);
        ytcpsocket_set_block(sockfd,0);
        connect(sockfd, (struct sockaddr *)&sa, sizeof(sa));
    }


    
    
    fd_set          fdwrite;
    struct timeval  tvSelect;
    FD_ZERO(&fdwrite);
    FD_SET(sockfd, &fdwrite);
    tvSelect.tv_sec  = timeout / 1000;
    tvSelect.tv_usec = (timeout % 1000) * 1000;
    int retval = select(sockfd + 1,NULL, &fdwrite, NULL, &tvSelect);
    if (retval<0) {
        return -2;
    }else if(retval==0){//timeout
        return -3;
    }else{
        int error=0;
        int errlen=sizeof(error);
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&errlen);
        if(error!=0){
            return -4;//connect fail
        }
        ytcpsocket_set_block(sockfd, 1);
        int set = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
        
        return sockfd;
    }
}
int ytcpsocket_close(int socketfd){
    return close(socketfd);
}
int ytcpsocket_pull(int socketfd,char *data,int len){
    int readlen=(int)read(socketfd,data,len);
    return readlen;
}
int ytcpsocket_send(int socketfd,const char *data,int len){
    int byteswrite=0;
    while (len-byteswrite>0) {
        int writelen=(int)write(socketfd, data+byteswrite, len-byteswrite);
        if (writelen<0) {
            return -1;
        }
        byteswrite+=writelen;
    }
    return byteswrite;
}

/**测试网络状况*/
ssize_t test_socket_state(int socketfd){
//    int t = send(socketfd, (void *)"0", 1, MSG_OOB);
    ssize_t t = write(socketfd, (void *)"0", 1);
//    printf("C测试网络连接%ld.\n", t);
    
    return t;
}

void set_keep_alive(int sockfd){
    int keepalive = 1; // 开启keepalive属性
    int keepidle = 2; // 如该连接在2秒内没有任何数据往来,则进行探测
    int keepinterval = 1; // 探测时发包的时间间隔为1 秒
    int keepcount = 4; // 探测尝试的次数.如果第1次探测包就收到响应了,则后2次的不再发.
    setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE, (void *)&keepalive , sizeof(keepalive ));
    setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPALIVE, (void*)&keepidle , sizeof(keepidle ));
    setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPINTVL, (void *)&keepinterval , sizeof(keepinterval ));
    setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPCNT, (void *)&keepcount , sizeof(keepcount ));
}

//return socket fd
int ytcpsocket_listen(const char *addr,int port){
    //create socket
    int socketfd=socket(AF_INET, SOCK_STREAM, 0);
    int reuseon   = 1;
    setsockopt( socketfd, SOL_SOCKET, SO_REUSEADDR, &reuseon, sizeof(reuseon) );
    //bind
    struct sockaddr_in serv_addr;
    memset( &serv_addr, '\0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = inet_addr(addr);
    serv_addr.sin_port = htons(port);
    int r=bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr));
    if(r==0){
        if (listen(socketfd, 128)==0) {
            return socketfd;
        }else{
            return -2;//listen error
        }
    }else{
        return -1;//bind error
    }
}
//return client socket fd
int ytcpsocket_accept(int onsocketfd,char *remoteip,int* remoteport){
    socklen_t clilen;
    struct sockaddr_in  cli_addr;
    clilen = sizeof(cli_addr);
    int newsockfd = accept(onsocketfd, (struct sockaddr *) &cli_addr, &clilen);
    char *clientip=inet_ntoa(cli_addr.sin_addr);
    memcpy(remoteip, clientip, strlen(clientip));
    *remoteport=cli_addr.sin_port;
    if(newsockfd>0){
        return newsockfd;
    }else{
        return -1;
    }
}


