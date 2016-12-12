//
//  VoiceUtils.swift
//  huarui
//
//  Created by sswukang on 15/4/17.
//  Copyright (c) 2015年 huarui. All rights reserved.
//


import AVFoundation

class VoiceUtils: NSObject, IFlySpeechRecognizerDelegate{
//MARK: - 属性
    private var _isr: IFlySpeechRecognizer
    private var _sentence = ""
    
    weak var delegate: VoiceResultDelegate?
    var namesDic = Dictionary<String, Array<String>>(){
        didSet{
            initAbnf(namesDic)
        }
    }
    
//MARK: - 方法
    private override convenience init(){
        self.init(namesDic: nil)
    }
    
    private init(namesDic: Dictionary<String, Array<String>>?){
        IFlySpeechUtility.createUtility("appid=\(IFLY_APPID)")
        self._isr = IFlySpeechRecognizer()
        super.init()
        
        setParam()
        
        if namesDic != nil{
            self.namesDic = namesDic!
        }
    }
    
    class func shareInstance() -> VoiceUtils {
        struct singleton{
            static var predicate: dispatch_once_t   = 0
            static var instance: VoiceUtils!
        }
        dispatch_once(&singleton.predicate, {
            singleton.instance = VoiceUtils()
        })
        return singleton.instance
    }
    
    
    
    
    /**设置参数*/
    private func setParam(){
        //关闭log
       // IFlySetting.showLogcat(false)
       IFlySetting.showLogcat(true)
        
        _isr.setParameter(nil, forKey: IFlySpeechConstant.TTS_AUDIO_PATH())
        
        
        _isr.setParameter("utf8", forKey: IFlySpeechConstant.TEXT_ENCODING())
        _isr.setParameter("asr.pcm", forKey: IFlySpeechConstant.ASR_AUDIO_PATH())
        //设置识别模式
        _isr.setParameter("asr", forKey: IFlySpeechConstant.IFLY_DOMAIN())
        _isr.setParameter("0", forKey: IFlySpeechConstant.ASR_SCH())
//        _isr.setParameter("zh_cn", forKey: IFlySpeechConstant.LANGUAGE())
        _isr.setParameter("4000", forKey: IFlySpeechConstant.VAD_BOS())
        _isr.setParameter("1000", forKey: IFlySpeechConstant.VAD_EOS())
        _isr.setParameter(IFlySpeechConstant.TYPE_CLOUD(), forKey: IFlySpeechConstant.ENGINE_TYPE())
        _isr.setParameter("0", forKey: IFlySpeechConstant.ASR_PTT())
        _isr.setParameter("json", forKey: IFlySpeechConstant.RESULT_TYPE())
        _isr.delegate = self
        
    }

    func initAbnf(nameDic: Dictionary<String, Array<String>>){
        //读语法文件
        var path = NSBundle.mainBundle().resourcePath!
        
       
      // print(nameDic)
       // print("语法文件路径\(path)")
        
     //   path += "/grammar.abnf"
             path += "/grammar.abnf"
        var gram = String(try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding))
        
        
        for item in nameDic {
            gram += "\n$\(item.0) = "
            
            if item.1.count > 0 {
                for name in item.1{
                    
                    
                    //斌 这里是关键 判断了是否存在空的字符串 解决语音报错10703的错误的bug
                    if name.isEmpty {
                        
                        
                    }
                    
                    else{
                    
                     gram += " \"\(name)\" |"
                        
                        
                    }
                }
            } else {
                
                gram += "\"nil\" ";
            }
            
            //删除最后一个字符
            gram.removeAtIndex(gram.endIndex.predecessor())
            
          //  gram.removeAtIndex(gram.endIndex.predecessor())
            gram += ";"
            
            
            
           
        }
  
      
      
      
 

//        Log.debug("_________________Grammar__________________")
//        Log.debug(gram)
//        Log.debug("__________________________________________")
        //上传
        _isr.buildGrammarCompletionHandler({
            (gramID , err) in
            if err == nil {
                Log.verbose("上传语法文件出错(\(err.errorCode()))：\(err.errorDesc())")
              //斌注释
                print("上传语法文件出错(\(err.errorCode()))：\(err.errorDesc())")
                return
            }
            NSUserDefaults.standardUserDefaults().setValue(gramID, forKeyPath: "grammarID")
            Log.verbose("上传语法文件成功，GrammarID：\(gramID)")
           print("上传语法文件成功，GrammarID：\(gramID)")
            }, grammarType: "abnf", grammarContent: gram)
        
       
        //斌 这里的打印可以看到语法文件的具体内容 
         // print("gram最后是\(gram)")
       // print("--------------------------------------")
    }
    //启动语法识别
    func startGramListening(){
        if let gramId = NSUserDefaults.standardUserDefaults().valueForKey("grammarID") as? String {
            _isr.setParameter(gramId, forKey: IFlySpeechConstant.CLOUD_GRAMMAR())
        }
        
        
     
        _isr.startListening()
    }
    
    
//MARK: - 结果回调
    
    @objc func onBeginOfSpeech() {
        Log.debug("onBeginOfSpeech")
        _sentence = ""
		VoiceDialog.showWithVolume("开始说话", cancelHandler: {
			self._isr.stopListening()
		})
    }
    
    @objc func onCancel() {
        Log.debug("onCancel")
        print("取消");
        
    }
    
    @objc func onEndOfSpeech() {
		Log.debug("onEndOfSpeech")
        VoiceDialog.showWithWaiting("识别中...")
        print("正在识别中")
    }
    
    func onError(errorCode: IFlySpeechError!) {
        if errorCode.errorCode() == 10119{
            delegate?.voiceResult?(onError: "您好像没有说话哦", errCode: errorCode.errorCode())
			VoiceDialog.showWithWarning("您好像没有说话哦")
        }
        else if errorCode.errorCode() != 0 {
            Log.debug("onError(\(errorCode.errorCode())): \(errorCode.errorDesc())")
            //斌注释  打印错误消息
            print("onError(\(errorCode.errorCode())): \(errorCode.errorCode())")
            
            
            delegate?.voiceResult?(onError: errorCode.errorDesc(), errCode: errorCode.errorCode())
			
			VoiceDialog.showWithWarning("\(errorCode.errorDesc())(\(errorCode.errorCode()))")
        }
    }
    
    @objc func onResults(results: [AnyObject]!, isLast: Bool) {
        Log.debug("onResults is last? : \(isLast)")
        if results == nil {
            return
        }
        
        
        let dic: NSDictionary = results[0] as! NSDictionary
        for key in dic {
            let str = "\(key.key as! String)"
            Log.debug("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
            Log.debug(str)
            Log.debug("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
            if let data = str.dataUsingEncoding(NSUTF8StringEncoding) {
                var error: NSError?
                let json = JSON(data:data, options: .AllowFragments, error: &error)
                let result = parseGrammarResult(json["ws"][0]["cw"][0]["mn"][0], score: json["ws"][0]["cw"][0]["sc"].intValue)
                if isLast && result.0 == false{
					VoiceDialog.showWithWarning(result.1)
                } else {
                    VoiceDialog.dismiss()
                }
            }
        }
        
    }
    
    @objc func onVolumeChanged(volume: Int32) {
		
		VoiceDialog.setVolume(Float(volume) * 1.3 / 30.0)
    }
    
    
    //解析语法识别的结果
    func parseGrammarResult(mn: JSON, score: Int?) -> (Bool, String){
        
        
        //斌注释 语法识别的结果
        
        DDLogInfo("语法识别的结果")
        
        
        if score == nil {
            delegate?.voiceResult?(onError: "无结果", errCode: -1)
            return (false, "没有结果")
        }
        let id      = mn["id"].string
        if id != nil && id == "nomatch"{
            return (false, "没有结果")
        }
        let devType = mn["device_type"].string
        let floor   = mn["floor"].string
        let room    = mn["room"].string
        let action  = mn["action"].string
        let device  = mn["device"].string
        let scene   = mn["scene"].string
        
        Log.debug("devType = \(devType)")
        Log.debug("action  = \(action)")
        Log.debug("floor   = \(floor)")
        Log.debug("room    = \(room)")
        Log.debug("device  = \(device)")
        Log.debug("score   = \(score)")
        Log.debug("scene   = \(scene)")
        
        
        VoiceDialog.dismiss()
        if devType == "继电器" {
            delegate?.voiceResult?(onRelayResult: floor, room: room, device: device, action: action, score: score!)
        }
        else if devType == "电机" {
            delegate?.voiceResult?(onMotorResult: floor, room: room, device: device, action: action, score: score!)
        }
        else if devType == "情景" {
            delegate?.voiceResult?(onSceneResult: scene, score: score!)
        }
        return (true, "")
    }

}

//MARK: - 语音最终识别结果代理

@objc protocol VoiceResultDelegate{
    optional func voiceResult(onRelayResult floor: String?, room: String?, device: String?, action: String?, score: Int)
    
    optional func voiceResult(onMotorResult floor: String?, room: String?, device: String?, action: String?, score: Int)
    
    optional func voiceResult(onAirResult floor: String, room: String, device: String, mode: String, temp: String, speed: Int, score: Int)
    
    optional func voiceResult(onSceneResult scene: String?, score: Int)
    
    optional func voiceResult (onError errMsg: String, errCode: Int32)
}
