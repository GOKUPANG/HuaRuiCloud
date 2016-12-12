//
//  VoiceDialog.swift
//  VoiceDialog
//
//  Created by sswukang on 15/4/29.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class VoiceDialog: UIView {
//MARK: - 私有属性
    private enum ShowingState {
        case VolumeInput
        case Waiting
        case Warning
        case Unshowed
    }
    private var _titleColor = UIColor(red: 4/255.0, green: 168/255.0, blue: 247/255.0, alpha: 170/255.0)
    private var _titleSize:CGFloat  = 20
	private var _dialog: UIView!
	private var _blurView: UIView!
    /**音量块*/
    private var _volFieldViews = [UIView]()
    private var _titleLabel: UILabel!
    /**正在识别*/
    private var _waitingImgView: UIImageView!
    /**没有结果*/
    private var _warningImgView: UIImageView!
    /**当前显示的状态*/
    private var _showingState = ShowingState.Unshowed
	///
	private var _cancelVolumInputHandler: ((Void)->Void)?
    
    
//MARK: - 公共属性
    var maskBackgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
    var numOfVolField = 10
    var volFieldColor = UIColor(red: 4/255.0, green: 168/255.0, blue: 247/255.0, alpha: 170/255.0)

    /**音量值，必须介于0-1之间*/
    var volume: Float = 0{
        didSet{
            if _volFieldViews.count < 1 || _showingState != .VolumeInput {
                return
            }
            let valve: Int
            if volume > 1{
                valve = numOfVolField
            }
            else if volume < 0{
                valve = 0
            }
            else {
                valve = Int(volume * Float(numOfVolField))
            }
            for i in 0...numOfVolField {
                if i < valve {
                    _volFieldViews[i].hidden = false
                } else {
                    _volFieldViews[i].hidden = true
                }
            }
        }
    }
    
//MARK: - 方法
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
		//隐藏
		self.layer.opacity = 0
		
		//设置背景
		self.backgroundColor = maskBackgroundColor
		//背景监听点击事件
		let tapGeature = UITapGestureRecognizer(target: self, action: #selector(VoiceDialog.onViewTap(_:)))
		self.addGestureRecognizer(tapGeature)
		
		/*****************添加dialog******************/
		
		/****dialog背景****/
		let dialogWidth  = frame.width * 0.7   //dialog宽度是父控件的3/5倍，宽高比4:3
		let dialogHeight = dialogWidth * (3/4)
		let posX = frame.minX + frame.width  / 2 - dialogWidth  / 2
		let posY = frame.minY + frame.height / 2 - dialogHeight / 2
		_dialog = UIView(frame: CGRectMake(posX, posY, dialogWidth, dialogHeight))
		_dialog.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.88)
		_dialog.layer.cornerRadius = 20
		
		/****音量块****/
		
		//在dialog上添加音量块。dialog的2/3高度减dialog的1/10用来显示音量块，1/3用来显示文字标题
		//a.音量块的高度 = （dialog高度 * 2/3 - dialog高度 * 1/10 - 所有间隙和）/ 音量块数
		//b.其中间隙又等于 = 音量块高度 * 1/3
		//简化上面两条方程可得
		let volFieldH = (dialogHeight * 13) / CGFloat(30 * numOfVolField + 10)
		//        let volFieldH:CGFloat = 5 b
		let fieldGapH = volFieldH / 3
		//第一块音量块的长度等于dialog的1/2，居中位置
		//最后（最小）音量块的长度等于dialog的1/10
		let volMaxW = dialogWidth / 2
		let volMinW = dialogWidth / 20
		//相邻的两个音量块的左右长度差距
		let volWDiff = (volMaxW - volMinW) / 2 / CGFloat(numOfVolField)
		var volFieldW = volMaxW
		//其中第一个音量块距离顶部等于dialog高度的1/10
		var baseX = (dialogWidth / 2) - (volMaxW / 2)
		var baseY =  dialogHeight / 10
		
		for i in 0...numOfVolField {
			volFieldW = volMaxW - (CGFloat(i) * volWDiff * 2)
			let fieldView = UIView(frame: CGRectMake(baseX, baseY, volFieldW, volFieldH))
			fieldView.backgroundColor = volFieldColor
			self._volFieldViews.append(fieldView)
			fieldView.hidden = true
			_dialog.addSubview(fieldView)
			
			baseX += volWDiff
			baseY += volFieldH + fieldGapH
		}
		
		/****提示文字****/
		_titleLabel = UILabel(frame: CGRectMake(0, baseY, dialogWidth, _dialog.frame.height - _volFieldViews[_volFieldViews.count-1].frame.maxY))
		_titleLabel.textAlignment = NSTextAlignment.Center
		_titleLabel.font = UIFont.systemFontOfSize(_titleSize)
		_titleLabel.textColor = _titleColor
		_dialog.addSubview(_titleLabel)
		
		/**添加“正在识别”的图像*/
		let imgViewH = _titleLabel.frame.minY - dialogHeight / 10
		_waitingImgView = UIImageView(frame: CGRectMake(0, 0 + dialogHeight/10, _dialog.frame.width, imgViewH))
		_waitingImgView.image = UIImage(named: "voice_waiting")
		_waitingImgView.contentMode = UIViewContentMode.ScaleAspectFit
		_waitingImgView.hidden = true
		_dialog.addSubview(_waitingImgView)
		
		/**添加“没有结果”的图像*/
		_warningImgView = UIImageView(frame: CGRectMake(0, 0 + dialogHeight/10, _dialog.frame.width, imgViewH))
		_warningImgView.image = UIImage(named: "voice_warning")
		_warningImgView.contentMode = UIViewContentMode.ScaleAspectFit
		_warningImgView.hidden = true
		_dialog.addSubview(_warningImgView)
		
		self._volFieldViews = Array(self._volFieldViews.reverse())
		self.volume = volume + 0.0
		
		//模糊背景
		//当前iOS版本大于或等于8.0
		if #available(iOS 8.0, *) {
			_blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
		} else {
			UIGraphicsBeginImageContextWithOptions(bounds.size, true, 1.01)
			
			let imgContext = UIGraphicsGetCurrentContext()
			let window = UIApplication.sharedApplication().keyWindow!
			CGContextSaveGState(imgContext!);
			CGContextTranslateCTM(imgContext!, window.center.x, window.center.y);
			CGContextConcatCTM(imgContext!, window.transform);
			CGContextTranslateCTM(imgContext!, -window.bounds.width * window.layer.anchorPoint.x, -window.bounds.height * window.layer.anchorPoint.y)
			window.layer.renderInContext(imgContext!)
			CGContextRestoreGState(imgContext!);
			
			let screenshot = UIGraphicsGetImageFromCurrentImageContext();
			
			
			UIGraphicsEndImageContext()
			
			let filter = CIFilter(name: "CIGaussianBlur")
			filter!.setValue(CIImage(image: screenshot!), forKey: kCIInputImageKey)
			filter!.setValue(10.0, forKey: kCIInputRadiusKey)
			let result = filter!.outputImage
			let context = CIContext(options: nil)
			let outImage = context.createCGImage(result!, fromRect: bounds)
			let blurImage = UIImage(CGImage: outImage!)
			
			_blurView = UIImageView(image: blurImage)
		}
		_blurView.frame = bounds
		
		self.addSubview(_blurView)
		self.addSubview(_dialog)
    }
	
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
		self.opaque = false
		//隐藏
		self.layer.opacity = 0
    }
	
    func onViewTap(gesture: UITapGestureRecognizer) {
        switch gesture.state{
        case .Ended:
			if _showingState == .VolumeInput {
				_cancelVolumInputHandler?()
			} else {
				self.dismissDialog(nil)
			}
        default:
            break
        }
    }
	
    private func hideAllVolFieldViews(){
        for fieldView in _volFieldViews {
            fieldView.hidden = true
        }
    }
    
    /**显示音量*/
    func showVolume(text: String, cancelHandler: ((Void)->Void)?) {
		self._cancelVolumInputHandler = cancelHandler
        if _showingState != .VolumeInput{
            _waitingImgView.hidden = true
            _warningImgView.hidden = true
            _titleLabel.text = text
        }
        _showingState = .VolumeInput
        self.volume = volume + 0
        UIView.transitionWithView(self, duration: 0.35, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.layer.opacity = 1
            }, completion: nil)
    }
    
    //显示正在识别
    func showWaiting(text: String){
        if _showingState == .Unshowed {
            showDialog(.Waiting)
        }
        if _showingState != .Waiting{
            _warningImgView.hidden = true
            _titleLabel.text = text
            hideAllVolFieldViews()
        }
        _showingState = .Waiting
        _waitingImgView.hidden = false
		
        _waitingImgView.startRotate(1000, duration: 1)
    }
    
    //显示警告
    func showWarning(text: String){
        if _showingState == .Unshowed {
            showDialog(.Warning)
        }
        if _showingState != .Warning{
            _waitingImgView.hidden = true
            _titleLabel.text = text
            hideAllVolFieldViews()
        }
        _showingState = .Warning
        _warningImgView.hidden = false
	}
	
	private func showDialog(state: ShowingState) {
		UIView.transitionWithView(self, duration: 0.35, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self._dialog.layer.opacity = 1
			}, completion: { (completed) in
				self._showingState = state
		})
	}
	
	/**隐藏_dialog*/
	func dismissDialog(completion: ((Void)->Void)?){
		if _showingState == .Warning {
			dismiss(nil)
			return
		}
		UIView.transitionWithView(self, duration: 0.3, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self._dialog.layer.opacity = 0
			}, completion: { (completed) in
				self._showingState = .Unshowed
		})
	}
	
	/**隐藏VoiceDialog*/
	func dismiss(completion: ((Void)->Void)?){
		UIView.transitionWithView(self, duration: 0.35, options: UIViewAnimationOptions.CurveEaseOut, animations: {
			self.layer.opacity = 0
			}, completion: {
				(comp) in
				self._showingState = .Unshowed
				self.removeFromSuperview()
				VoiceDialog.dialogInstance = nil
		})
	}

//MARK: - 静态方法
	private static var dialogInstance: VoiceDialog?
	
	class func showWithVolume(text: String, cancelHandler: ((Void)->Void)?) {
		if dialogInstance == nil {
			let window: UIView! = UIApplication.sharedApplication().delegate?.window!
			dialogInstance = VoiceDialog(frame: window.bounds)
			window.addSubview(dialogInstance!)
		}
		if let dialog = dialogInstance {
			dialog.showVolume(text, cancelHandler: cancelHandler)
		}
	}
	
	class func setVolume(volume: Float) {
		dialogInstance?.volume = volume
	}
	
	class func showWithWarning(text: String){
		if dialogInstance == nil {
			let window: UIView! = UIApplication.sharedApplication().delegate?.window!
			dialogInstance = VoiceDialog(frame: window.bounds)
			window.addSubview(dialogInstance!)
		}
		if let dialog = dialogInstance {
			dialog.showWarning(text)
		}
	}
	
	class func showWithWaiting(text: String){
		if dialogInstance == nil {
			let window: UIView! = UIApplication.sharedApplication().delegate?.window!
			dialogInstance = VoiceDialog(frame: window.bounds)
			window.addSubview(dialogInstance!)
		}
		if let dialog = dialogInstance {
			dialog.showWaiting(text)
		}
	}
	
	class func dismiss(){
		if let dialog = dialogInstance {
			dialog.dismiss({
				self.dialogInstance = nil
			})
		}
	}
}
