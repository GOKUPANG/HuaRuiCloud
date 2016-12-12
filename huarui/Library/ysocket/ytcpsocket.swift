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
import Foundation

@_silgen_name("ytcpsocket_connect") func c_ytcpsocket_connect(host:UnsafePointer<Int8>,port:Int32,timeout:Int32) -> Int32
@_silgen_name("ytcpsocket_close") func c_ytcpsocket_close(fd:Int32) -> Int32
@_silgen_name("ytcpsocket_send") func c_ytcpsocket_send(fd:Int32,buff:UnsafePointer<UInt8>,len:Int32) -> Int32
@_silgen_name("ytcpsocket_pull") func c_ytcpsocket_pull(fd:Int32,buff:UnsafePointer<UInt8>,len:Int32) -> Int32
@_silgen_name("ytcpsocket_listen") func c_ytcpsocket_listen(addr:UnsafePointer<Int8>,port:Int32)->Int32
@_silgen_name("ytcpsocket_accept") func c_ytcpsocket_accept(onsocketfd:Int32,ip:UnsafePointer<Int8>,port:UnsafePointer<Int32>) -> Int32
@_silgen_name("test_socket_state") func c_test_socket_state(socketfd:Int32) -> Int64
@_silgen_name("set_keep_alive") func c_set_keep_alive(socketfd:Int32)
@_silgen_name("get_error_str") func c_get_error_str(error: UnsafeMutablePointer<Int8>) -> Int

public class TCPClient:YSocket{
    /*
    * connect to server
    * return success or fail with message
    */
    //    public func connect(timeout t:Int)->(Bool,String, Int32){
    //        var rs:Int32=c_ytcpsocket_connect(self.addr, Int32(self.port),Int32(t))
    //        if rs>0{
    //            self.fd=rs
    //            return (true,"connect success", rs)
    //        }else{
    //            switch rs{
    //            case -1:
    //                return (false,"qeury server fail", rs)
    //            case -2:
    //                return (false,"connection closed", rs)
    //            case -3:
    //                return (false,"connect timeout", rs)
    //            default:
    //                return (false,"unknow err.code=\(rs)", rs)
    //            }
    //        }
    //    }
    
    /*
    * connect to server
    * return success or fail with message
    */
    let v = 0
    ///连接服务器
    ///
    ///- parameter timeout: 超时时间（毫秒）
    ///- returns: 如果连接成功返回nil，连接失败则返回相应错误描述。
    public func connect(timeout t:Int)->NSError?{
        let rs:Int32=c_ytcpsocket_connect(addr, port: Int32(port), timeout: Int32(t))
        if rs>0{
            self.fd=rs
            c_set_keep_alive(rs)
            return nil
        }else{
            var error: NSError?
			let errbuf = UnsafeMutablePointer<CChar>.alloc(256)
			c_get_error_str(errbuf)
			var errStr = String.fromCString(errbuf)
			errbuf.dealloc(256)
            switch rs{
            case -1:
                //"qeury server fail"
                error = NSError(domain: "查询服务器失败", code: Int(rs), userInfo: nil)
            case -2:
                //"connection closed"
                error = NSError(domain: "连接已关闭", code: Int(rs), userInfo: nil)
            case -3:
                //connect timeout"
                error = NSError(domain: "连接超时", code: Int(rs), userInfo: nil)
            default:
                //unknow error
				if errStr == nil { errStr = "未知错误" }
                error = NSError(domain: "\(errStr!)", code: Int(rs), userInfo: nil)
            }
            return error
        }
    }
    /*
    * close socket
    * return success or fail with message
    */
    public func close() -> NSError?{
        if self.fd != nil{
            c_ytcpsocket_close(self.fd!)
            self.fd = nil
            return nil
        }else{
            return NSError(domain: "Socket not open", code: HRErrorCode.SocketNotOpen.rawValue, userInfo: nil)
        }
    }
    
    ///send data
    ///
    ///- returns: 发送成功则返回nil；发送失败返回NSError，其code和domain属性都会设置。
    public func send(data:[UInt8]) -> NSError?{
        if let fd:Int32=self.fd{
            let sendsize:Int32=c_ytcpsocket_send(fd, buff: data, len: Int32(data.count))
            if Int(sendsize)==data.count{
                return nil
            }else{
                //send error
                return NSError(domain: "发送失败", code: Int(sendsize), userInfo: nil)
            }
        }else{
            return NSError(domain: "网络连接已断开", code: HRErrorCode.SocketNotOpen.rawValue, userInfo: nil)
        }
    }
    /*
    * send string
    * return success or fail with message
    */
    public func send(str s:String)->(Bool,String){
        if let fd:Int32=self.fd{
            let sendsize:Int32=c_ytcpsocket_send(fd, buff: s, len: Int32(strlen(s)))
            if sendsize==Int32(strlen(s)){
                return (true,"send success")
            }else{
                return (false,"send error")
            }
        }else{
            return (false,"socket not open")
        }
    }
    /*
    *
    * send nsdata
    */
    public func send(data d:NSData)->(Bool,String){
        if let fd:Int32=self.fd{
            var buff:[UInt8] = [UInt8](count:d.length,repeatedValue:0x0)
            d.getBytes(&buff, length: d.length)
            let sendsize:Int32=c_ytcpsocket_send(fd, buff: buff, len: Int32(d.length))
            if sendsize==Int32(d.length){
                return (true,"send success")
            }else{
                return (false,"send error")
            }
        }else{
            return (false,"socket not open")
        }
    }
    /*
    * read data with expect length
    * return success or fail with message
    */
    //    public func read(expectlen:Int)->([UInt8]?, Int){
    //        if let fd:Int32 = self.fd{
    //            var buff:[UInt8] = [UInt8](count:expectlen,repeatedValue:0x0)
    //            var readLen:Int32=c_ytcpsocket_pull(fd, &buff, Int32(expectlen))
    //            if readLen<=0{
    //                return (nil, -1)
    //            }
    //            var rs=buff[0...Int(readLen-1)]
    //            var data:[UInt8] = Array(rs)
    //            return (data, data.count)
    //        }
    //        return (nil, -1)
    //    }
    /*
    * read data with expect length
    * return success or fail with message
    */
    public func read(expectlen:Int,  error: NSErrorPointer)->([UInt8]?, Int){
        if let fd:Int32 = self.fd{
            var buff:[UInt8] = [UInt8](count:expectlen,repeatedValue:0x0)
            let readLen:Int32=c_ytcpsocket_pull(fd, buff: &buff, len: Int32(expectlen))
            if readLen<=0{
                if error != nil {
                    error.memory = NSError(domain: "Read error", code: Int(readLen), userInfo: nil)
                }
                return (nil, -1)
            }
            let rs=buff[0...Int(readLen-1)]
            let data:[UInt8] = Array(rs)
            return (data, data.count)
        }
        return (nil, -1)
    }
    
    ///读socket
    ///
    ///- parameter expectlen: 读取数据的长度（不一定能读到那么多，但是不会超过这个长度）
    ///- returns: 成功读到数据返回(data!, nil), 出错了则返回(nil, NSError!)
    public func read(expectlen:Int) -> ([UInt8]?, NSError?) {
        if let fd:Int32 = self.fd{
            var buff = [UInt8](count:expectlen,repeatedValue:0x0)
            let readLen = c_ytcpsocket_pull(fd, buff: &buff, len: Int32(expectlen))
            if readLen <= 0 {
                let err = NSError(domain: "Read error", code: Int(readLen), userInfo: nil)
                return (nil, err)
            }
            let rs=buff[0...Int(readLen-1)]
            return (Array(rs), nil)
        }
        return (nil, NSError(domain: "socket not open", code: HRErrorCode.SocketNotOpen.rawValue, userInfo: nil))
    }
    
    public func isConnected() -> Bool{
        if let fd = self.fd {
            if c_test_socket_state(fd) >= 0 {
                return true
            }
        }
        return false
    }
}

public class TCPServer:YSocket{
    
    public func listen()->(Bool,String){
        
        let fd:Int32=c_ytcpsocket_listen(self.addr, port: Int32(self.port))
        if fd>0{
            self.fd=fd
            return (true,"listen success")
        }else{
            return (false,"listen fail")
        }
    }
    public func accept()->TCPClient?{
        if let serferfd=self.fd{
            var buff:[Int8] = [Int8](count:16,repeatedValue:0x0)
            var port:Int32=0
            let clientfd:Int32=c_ytcpsocket_accept(serferfd, ip: &buff,port: &port)
            if clientfd<0{
                return nil
            }
            let tcpClient:TCPClient=TCPClient()
            tcpClient.fd=clientfd
            tcpClient.port=UInt16(port)
            if let addr=String(CString: buff, encoding: NSUTF8StringEncoding){
                tcpClient.addr=addr
            }
            return tcpClient
        }
        return nil
    }
    public func close()->(Bool,String){
        if let fd:Int32=self.fd{
            c_ytcpsocket_close(fd)
            self.fd=nil
            return (true,"close success")
        }else{
            return (false,"socket not open")
        }
    }
}


