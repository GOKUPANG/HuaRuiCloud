//
//  HRSocketConnection.swift
//  SmartBed
//
//  Created by sswukang on 15/7/9.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import Foundation

///默认的网络超时时间，单位：秒
let defaultTCPTimeout = Double(TCP_RCV_TIMEOUT) / 1000.0


///TCP连接类，本类只适用于基于HR8000系列主机协议的连接，所接收的帧必须遵循协议才会被接收，否则数据会被遗弃。
class HRSocketConnection: NSObject {
//MARK: - 内部结构体
    ///标志
    private struct Flags {
        ///是否正在接收网络数据包
        var isReceivingSocket    = false
        ///是否正在从缓冲中读协议帧, parsing
        var isParsingBuffer      = false
        ///是否正在判断回调的条件是否符合
        var isMatchingCondition  = false
        ///是否正在检查超时
        var isCheckingTimeout    = false
        ///是否已经连接
        var isConnected          = false
    }
    
    private struct Locks {
        ///回调池的锁
        let callbackPool    = NSLock()
        ///网络缓冲的锁
        let receiveBuffer   = NSLock()
        ///Socket网络接收线程的锁
        let socketQueueLock = NSLock()
        ///解析协议帧线程的锁
        let parseQueueLock  = NSLock()
        ///检测网络状况线程的锁
        let checkConnection = NSLock()
    }
    
//MARK: - *************私有属性****************
    private var _socketQueue: dispatch_queue_t
    private var _tcpConn : TCPClient
    private var _flags   : Flags
    private var _locks   : Locks
    ///网络数据接收的缓冲
    private var _rcvBuffer: [Byte]
    ///帧缓冲队列
    private var _frameBuffer: HRFrameQueue
    
    
    private var _filterPool      = Dictionary<Int, ((HRFrame)->Bool)>()
    private var _rcvCallbackPoll = Dictionary<Int, ((HRFrame?, NSError?)->Void)>()
    private var _startTimePool   = Dictionary<Int, NSTimeInterval>()
    private var _timeoutPool     = Dictionary<Int, Double>()
	
    private var _tag: Int = 0 {
        didSet {
            if _tag == Int.max {_tag = 0}
        }
    }
    
//MARK: - *************公开属性****************
    var hostAddr: String
    var hostPort: UInt16
    weak var delegate: HRSocketConnectionDelegate?
    ///是否已经连接
    var isConnected: Bool {get{return self._flags.isConnected}}
    
    
    
/****************************************************/

//MARK: - 方法
    init(hostAddr: String, hostPort: UInt16) {
        Log.debug("创建TCP Socket: host=\(hostAddr):\(hostPort)")
        self._socketQueue = dispatch_queue_create("com.huarui.socket.tcp", DISPATCH_QUEUE_CONCURRENT)
        self._tcpConn = TCPClient(addr: hostAddr, port: hostPort)
        self.hostAddr = hostAddr
        self.hostPort = hostPort
        self._flags   = Flags()
        self._locks   = Locks()
        self._rcvBuffer   = Array()
		self._frameBuffer = HRFrameQueue()
		super.init()
		
		//注册通知检测网络
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HRSocketConnection.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachChecker)
		reachChecker?.startNotifier()
	}
	
	convenience init(hostAddrValue: UInt32, hostPort: UInt16) {
		let bytes = hostAddrValue.getBytes()
		let hostAddrStr = "\(bytes[0]).\(bytes[1]).\(bytes[2]).\(bytes[3])"
		self.init(hostAddr: hostAddrStr, hostPort: hostPort)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
    
    ///连接服务器
    ///
    ///- parameter timeout:  超时时间，单位：毫秒
    ///- parameter callback: 结果回调，假如连接成功，callback的参数为nil；假如失败，callback的参数为失败信息
    func connectServer(timeout: Int, result: ((NSError?)->Void)?) {
        runOnSocketQueue({
            self._tcpConn.addr = self.hostAddr
            self._tcpConn.port = self.hostPort
            if let error = self._tcpConn.connect(timeout: timeout) {
                //连接失败
                self._flags.isConnected = false
                result?(error)
            } else {
                //连接成功
                self._flags.isConnected = true
				self._frameBuffer.open()
                self.delegate?.socketConnection(socketDidConnected: self)
				//发送通知
				NSNotificationCenter.defaultCenter().postNotificationName(kNotificationDidSocketConnected, object: self)
                result?(nil)
            }
        })
    }
    
    ///断开连接
    func disconnect() {
        self._flags.isReceivingSocket = false
        self._flags.isParsingBuffer   = false
        _tcpConn.close()
        _frameBuffer.close()
        self._flags.isConnected = false
    }

//MARK: - 发送数据
    
    ///发送一帧数据
    ////
    ///- returns: 返回nil代表成功，否则返回error
    func send(frame: HRFrame) -> NSError?{
        if let data = frame.toTransmitFrame() {
            Log.verbose("发送数据包:\n\(frame.toTransmitFrame()!)")
            return _tcpConn.send(data)
        } else {
            return NSError(domain: "数据包超过最大长度", code: HRErrorCode.UnknowError.rawValue, userInfo: nil)
        }
    }
    
    ///发送一个帧，同时无条件接收一个帧
    ///
    ///- parameter frame:    要发送的帧
    ///- parameter receive:  接收数据的闭包回调，无条件接收，只要Socket接收到了数据包，就会立即调用此闭包回调
    func sendAndReceive(frame: HRFrame, receive: ((HRFrame?, NSError?)->Void) ) {
        self.sendAndReceive(frame, filter: {(_) in return true}, receive: receive)
    }
    
    ///发送一个数据包，同时接收一个数据包
    ///
    ///- parameter data: 发送的数据
    ///- parameter filter:    接收过滤，给一个闭包，闭包的参数是接收到的数据，闭包内自行判断是否是想要的包，如果闭包返回true，则引发`rcvCallback`的回调。
    ///- parameter receive:     接收数据的闭包回调，符合条件的数据包
    func sendAndReceive(frame: HRFrame, filter: (HRFrame)->Bool, receive: ((HRFrame?, NSError?)->Void)) {
        if let error = send(frame) { //发送失败
            receive(nil, error)
        } else {    //发送成功
            self.receive(filter, receive: receive)
        }
    }
    
    
    
    ///发送一个数据包，同时接收一个数据包
    ///
    ///- parameter timeout: 超时时间, 单位为秒
    ///- parameter frame: 发送的数据
    ///- parameter filter:    接收过滤，给一个闭包，闭包的参数是接收到的数据，闭包内自行判断是否是想要的包，如果闭包返回true，则引发`rcvCallback`的回调。
    ///- parameter receive:     接收数据的闭包回调，符合条件的数据包
    func sendAndReceive(timeout: Double, frame: HRFrame, filter: (HRFrame)->Bool, receive: ((HRFrame?, NSError?)->Void)) {
        if let error = send(frame) { //发送失败
            receive(nil, error)
        } else {    //发送成功
            self.receive(timeout, filter: filter, receive: receive)
        }
    }

//MARK: - 接收数据
    
    ///接收一个frame，无条件接收，会有超时返回
    ///
    ///- parameter receive:  接收数据的闭包回调
    func receive(willTimeout receive: (HRFrame?, NSError?)->Void){
        self.receive(defaultTCPTimeout, filter: {(_) in return true}, receive: receive)
    }
    
    ///接收frames，无条件接收，永不超时
    ///
    ///- parameter receive:  接收数据的闭包回调
    func receive(noTimeout receive: (HRFrame)->Void ) -> Int {
        return self.receive(0, filter: {(_) in return true}, receive: {
            (frame, error) in
            if frame == nil {
                return
            } else {
                receive(frame!)
            }
        })
    }
    
    ///接收一个数据包, 带闭包条件，默认5秒之后超时返回
    ///
    ///- parameter filter：接收条件，给一个闭包，闭包的参数是接收到的数据，闭包内自行判断是否是想要的包，如果闭包返回true，则引发rcvCallback的回调。:
    ///- parameter recvCallback:: 接收数据的闭包回调
    func receive(filter: (HRFrame)->Bool, receive: (HRFrame?, NSError?)->Void) {
        self.receive(defaultTCPTimeout, filter: filter, receive: receive)
    }
    
    ///接收一个数据包, 带闭包条件。
    ///
    ///- parameter timeout: 超时时间，单位为秒，设置0为永不超时。
    ///- parameter filter: 每次网络接受到数据包，会调用filter闭包询问是否符合接收要求，如果符合，则应该返回true，这时，当前接收到的数据包会立即返回给callback，之后filter不会再接收数据包了（除非超时时间设置为0）；如果filter返回的是false，即当前数据包不符合条件，那么下一次网络接收到数据包仍然会调用filter，直到超时时间到为止。
    ///- parameter callback: 如果filter返回的是true，callback闭包的参数就是接收到的网络数据包，如果接收超时，callback的参数就是nil
    ///- returns: 当timeout参数传入值大于0时，返回0；当timeout参数传入为0时，返回值为接收标记，可以利用此标记注销接收。为什么要注销接收呢？因为如果接收是永不超时的话，后台线程将一直都会返回符合条件的数据，有时候程序并不需要继续接收了，那么就要注销它，以免浪费CPU资源。注销可以调用`unregisterReceive(tag:)`
    func receive(timeout:Double, filter: (HRFrame)->Bool, receive: (HRFrame?, NSError?)->Void) -> Int{
        let ret = registerReceiveCallback(timeout, filter: filter, callback: receive)
        return timeout == 0 ? ret : 0
    }
    
//MARK: - 处理回调
    
    ///注册一个接收回调
    private func registerReceiveCallback(timeout: Double, filter: (HRFrame)->Bool, callback: (HRFrame?, NSError?)->Void) -> Int {
        self._locks.callbackPool.lock()
		_tag += 1
        let tag       = _tag
        let startTime = NSDate().timeIntervalSince1970
        _startTimePool[tag]   = startTime
        _timeoutPool[tag]     = timeout
        _filterPool[tag]   = filter
        _rcvCallbackPoll[tag] = callback
        self._locks.callbackPool.unlock()
        
        self.startSocketReceive()
        self.startCheckTimeout()
        
//        Log.verbose("注册了一个回调，tag=\(tag)")
        return tag
    }
    
    ///注销一个接收回调，内部使用，该方法为原子方法
    private func unregisterReceiveCallback(tag: Int) {
        if _filterPool[tag] != nil {
            _filterPool.removeValueForKey(tag)
        } else {
//            Log.verbose("conditionPool[\(tag)] = nil")
        }
        if _rcvCallbackPoll[tag] != nil {
            _rcvCallbackPoll.removeValueForKey(tag)
        } else {
//            Log.verbose("callbackPool[\(tag)] = nil")
        }
        if _timeoutPool[tag] != nil {
            _timeoutPool.removeValueForKey(tag)
        } else {
//            Log.verbose("timeoutPool[\(tag)] = nil")
        }
        if _startTimePool[tag] != nil {
            _startTimePool.removeValueForKey(tag)
        } else {
//            Log.verbose("startTimePool[\(tag)] = nil")
        }
//        Log.verbose("注销了一个Callback,tag=\(tag)")
    }
    
    ///注销一个接收回调
    func unregisterReceive(tag: Int) {
        self._locks.callbackPool.lock()
        self.unregisterReceiveCallback(tag)
        self._locks.callbackPool.unlock()
    }
    
//MARK: - Socket Receive 接收线程
    
    private func startSocketReceive(){
        if _flags.isReceivingSocket { return }
        _flags.isReceivingSocket = true
        runOnSocketQueue({
            if !self._locks.socketQueueLock.tryLock(){
                return
            }
//            dispatch_sync(self._socketQueue, {
			while(self._flags.isReceivingSocket) {
				
				let (data, error) = self._tcpConn.read(DATA_FRAME_MAX*4)
				
				if data == nil { //出错了
					Log.warn("接收到一个nil包，原因:\(error?.localizedDescription)")
					if error!.code <= 0 {
						self._tcpConn.close()
						self._flags.isConnected = false
						Log.warn("Socket连接关闭，停止接收！")
						self.delegate?.socketConnection(socketDidDisconnected: self)
						//发送通知
						NSNotificationCenter.defaultCenter().postNotificationName(
								kNotificationDidSocketDisconnected,
								object: self )
						//检测网络是否可用
						if reachChecker!.currentReachabilityStatus !=
							.NotReachable {
							self.delegate?.socketConnection(networkAvailable: self, type: reachChecker!.currentReachabilityStatus)
						}
						self._flags.isReceivingSocket = false
						self._flags.isParsingBuffer   = false
						break
					}
					continue
				}
//                    Log.verbose("TCP线程：接收到了一个包（\(data!.count):\n\(data!)")
				//把数据包写到缓冲中
				self.runOnSocketQueue({
					self._locks.receiveBuffer.lock()
					self._rcvBuffer += data!
					self._locks.receiveBuffer.unlock()
					self.startParseBuffer()
				})
			}
			self._flags.isReceivingSocket = false
//            })
            self._locks.socketQueueLock.unlock()
            
        })
        return
    }
    
    
    ///停止接收线程
    func stopSocketReceive(){
        //停止socket接收
        self._flags.isReceivingSocket = false
        //停止解析帧
        self._flags.isParsingBuffer   = false
    }
  
// MARK: - Parse Buffer 解析协议帧线程
    
    ///从缓冲中读出协议帧
    private func startParseBuffer() {
        if self._flags.isParsingBuffer { return }
        self._flags.isParsingBuffer = true
        runOnSocketQueue({
            if !self._locks.parseQueueLock.tryLock() {
                return
            }
            while(self._flags.isParsingBuffer && self._rcvBuffer.count > 0) {
                //复制一份buffer, 避免与_rcvBuffer冲突，也没必要上锁减慢速度，注意：数组的复制拷贝是在swift beta3之后才有的
                var cloneBuffer = self._rcvBuffer
                //读帧头
                if cloneBuffer[0] != 0xAA {
                    //如果不是协议头，则去除第0个元素，并重新开始读下一个字节
                    self._locks.receiveBuffer.lock()
                    let byte = self._rcvBuffer.removeAtIndex(0)
                    self._locks.receiveBuffer.unlock()
                    Log.debug("startParseBuffer:帧头部第一个字节不为0xAA, 已去除第一个字节:\(byte)")
                    continue
                }
                //读帧长度
                if cloneBuffer.count < 3 {
                    //如果缓冲长度不足3，则无法读取到帧长度，所以睡眠5毫秒
                    usleep(5_000)
                    Log.debug("startParseBuffer:缓冲区长度不足3字节，睡眠5毫秒再解析")
                    continue
                }
                let frameLen = Int(cloneBuffer[1]) + Int(cloneBuffer[2]) << 8
                
                if frameLen + 5 > DATA_FRAME_MAX{    //超过最大长度，说明读错了
                    self._locks.receiveBuffer.lock()
                    let byte = self._rcvBuffer.removeAtIndex(0)
                    self._locks.receiveBuffer.unlock()
                    Log.debug("startParseBuffer:frameLen超过最大长度值(\(DATA_FRAME_MAX))。已去除第一个字节:\(byte)")
                    continue
                }
                //读结束符
                if cloneBuffer.count < 3 + frameLen + 2{
                    usleep(50_000)	//睡眠50ms
                    Log.debug("startParseBuffer:frame长度太小。帧长度:\(frameLen + 5)， 实际长度：\(cloneBuffer.count).")
                    continue;
                }
                let endByte = cloneBuffer[frameLen+3+1]
                if endByte != 0x55{
                    self._locks.receiveBuffer.lock()
                    let byte = self._rcvBuffer.removeAtIndex(0)
                    self._locks.receiveBuffer.unlock()
                    Log.debug("startParseBuffer:数据帧不以0x55结尾。已去除第一个字节:\(byte)")
                    continue;
                }
                //校验
                var temp:Byte = 0
                let frameData = Array(cloneBuffer[0...frameLen+4])
                for b in frameData[3...frameData.count-3]{
                    temp = temp &+ b
                }
                if temp != cloneBuffer[frameLen+3] {
                    //校验出错
                    self._locks.receiveBuffer.lock()
                    let byte = self._rcvBuffer.removeAtIndex(0)
                    self._locks.receiveBuffer.unlock()
                    Log.debug("startParseBuffer:这帧数据没有通过校验。已去除第一个字节:\(byte)")
                    continue
                }
				
//				Log.verbose("提取出一帧数据(\(frameData.count):\n\(frameData))")
				
                //frameData就是符合以0xAA开头，0x55结尾等条件的协议帧
                if let frame = HRFrame.initWithData(frameData) {
//                    Log.verbose("写到frameBuffer")
                    self._frameBuffer.write(frame)
                    //写入一个frame，开始matching condition
                    self.startMatchCondition()
                }
                self._locks.receiveBuffer.lock()
                self._rcvBuffer.removeRange(0..<frameLen+5)
                self._locks.receiveBuffer.unlock()
        
            }
            self._flags.isParsingBuffer = false
            self._locks.parseQueueLock.unlock()
        })
    }
	
    
// MARK: - Match condition 判断framebuffer中的帧是否符合receive callback的条件
    
    ///从frame buffer中读帧
    private func startMatchCondition() {
        if self._flags.isMatchingCondition { return }
        self._flags.isMatchingCondition = true
        runOnSocketQueue({
            //回调池里至少要有一个回调才会循环读
            while(self._flags.isMatchingCondition && self._rcvCallbackPoll.count > 0) {
                //从缓冲区中读出一个帧，无帧时会阻塞
                let frame = self._frameBuffer.read()
//                Log.verbose("$$从frameBuffer中拿走一帧数据")
                if frame == nil {  //等于nil代表关闭了frame buffer
                    self._flags.isMatchingCondition = false
                    return
                }
                //判断是否是异常帧，如果是，则不往上返回，上层将会超时
//                if let exception = frame!.isExceptionFrame {
//                    Log.warn("接收到异常帧：\(exception.domain)(\(exception.code))")
//                
//                    continue
//                } else {
                    //获得receive callback回调池的锁
                    self._locks.callbackPool.lock()
                    //循环条件回调池，判断条件是否符合
                    for (tag, condition) in self._filterPool {
                        if condition(frame!) {
                            //条件成立，执行回调，并注销回调
                            let callback = self._rcvCallbackPoll[tag]
                            //在另外一个线程调用callback，以免发生死锁
                            runOnGlobalQueue({
                                callback?(frame, nil)
                                return
                            })
                            //如果timeout是0的回调，则不注销，如果不为0，则注销它
                            if self._timeoutPool[tag] != 0 {
                                self.unregisterReceiveCallback(tag)
                            }
                        }
                    }
//                }
                //释放锁并开始检测超时
                self._locks.callbackPool.unlock()
                self.startCheckTimeout()
            }
            self._flags.isMatchingCondition = false
        })
    }

//MARK: - Check Timeout 超时检测
    
    ///检测超时的callback，如果超时则调用callback，并注销；如果超时时间等于或小于0，则为不会超时。
    private func startCheckTimeout() {
        if self._flags.isCheckingTimeout { return }
        self._flags.isCheckingTimeout = true
        //如果回调池中没有回调，则返回
        if self._rcvCallbackPoll.count == 0 {
            self._flags.isCheckingTimeout = false
            return
        } else {
            runOnSocketQueue({
                self._locks.callbackPool.lock()
                let now = NSDate().timeIntervalSince1970
                for (tag, start) in self._startTimePool {
                    let timeout = self._timeoutPool[tag]
                    if timeout <= 0 {
                        continue
                    }
                    if (now - start > timeout) { //如果已经超时
                        let callback = self._rcvCallbackPoll[tag]
                        //在另外一个线程调用callback，以免发生死锁
                        runOnGlobalQueue({
                            callback?(nil, NSError(domain: "超时", code: HRErrorCode.Timeout.rawValue, userInfo: nil))
                            return
                        })
                        self.unregisterReceiveCallback(tag)
                        
                        self._locks.callbackPool.unlock()
                        self._flags.isCheckingTimeout = false
                        self.startCheckTimeout()
                        return
                    }
                }
                //没有符合条件的，先解开锁，睡眠200ms再启动
                self._locks.callbackPool.unlock()
                usleep(200 * UInt32(NSEC_PER_USEC))
                self._flags.isCheckingTimeout = false
                self.startCheckTimeout()
            })
        }
    }
	
//MARK: - 私有方法
    
    private func runOnSocketQueue(block: ()->Void) {
        dispatch_async(self._socketQueue, block)
    }
	
	 /// 网络状况改变
	@objc private func reachabilityChanged(notification: NSNotification) {
		Log.warn("HRSocketConnection reachabilityChanged to \(reachChecker!.currentReachabilityStatus)")
		switch reachChecker!.currentReachabilityStatus {
		case .NotReachable:
			self.disconnect()
		case .ReachableViaWiFi:
			self.delegate?.socketConnection(networkAvailable: self, type: .ReachableViaWiFi)
		case .ReachableViaWWAN:
			self.delegate?.socketConnection(networkAvailable: self, type: .ReachableViaWWAN)
		}
	}
	
}




//MARK: - HRBufferQueue

/**帧队列，按先进先出规则读写，符合生产者消费者模型*/
class HRFrameQueue {
    private var _enable = true
    private var _buffer = [HRFrame]()
    
    /**条件锁，条件=0代表没有数据，条件=1代表有数据*/
    private let _lock = NSConditionLock(condition: 0)
    
    var count: Int { get{ return _buffer.count } }
    
    ///从队列中读取一个frame，如果队列里有frame，立即返回，如果没有frame，则阻塞直到有frame，该方法为原子操作，多线程调用不会导致冲突。
    ///
    ///- returns: 如果队列已经关闭，则返回nil
    func read() -> HRFrame? {
        var frame: HRFrame?
        if _buffer.count == 0 {  //无内容，阻塞
            _lock.lockWhenCondition(1) //这里阻塞等待条件
            if !_enable {   //如果队列已经关闭
                _buffer.removeAll(keepCapacity: false)
                _lock.unlockWithCondition(0)
                return nil
            }
            frame = _buffer.removeAtIndex(0)
            if _buffer.count == 0{
                _lock.unlockWithCondition(0)
            } else {
                _lock.unlockWithCondition(1)
            }
            return frame
        } else {        //有内容
            _lock.lock()
            frame = _buffer.removeAtIndex(0)
            if _buffer.count == 0{
                _lock.unlockWithCondition(0)
            } else {
                _lock.unlockWithCondition(1)
            }
            return frame
        }
    }
    
    /**往frame队列中写一个数据包*/
    func write(frame: HRFrame){
        _lock.lock()
        _buffer.append(frame)
        _lock.unlockWithCondition(1)
    }
    
    ///关闭队列，注意：队列之后，里面的数据都会清空
    func close() {
        _enable = false
        //清空缓冲
        write(HRFrame())
    }
    
    func open() {
        _enable = true
    }
}

//MARK: - HRSocketConnectionDelegate
protocol HRSocketConnectionDelegate: class {
    ///Socket连接成功
    func socketConnection(socketDidConnected tcpConn: HRSocketConnection)
    /**Socket连接断开*/
    func socketConnection(socketDidDisconnected tcpConn: HRSocketConnection)
	/**
	网络可用
	
	- parameter tcpConn: socket连接
	- parameter type:    网络类型
	*/
	func socketConnection(networkAvailable tcpConn: HRSocketConnection, type: Reachability.NetworkStatus)
	
}