//
//  TaskTableViewCell.swift
//  huarui
//
//  Created by sswukang on 15/10/24.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 情景、定时任务、传感器联动绑定的设备的cell
class SceneBindCell: UITableViewCell {
	
	weak var sceneBind: HRDevInScene! {
		didSet {
			if oldValue != nil {
				setNeedsDisplay()
			}
		}
	}
	var enabled: Bool = true
	
	private var segSwitch: DVSwitch?
	private var messageTextLabel: UILabel?
	private var rgbFieldView: UIView?
	
	init(style: UITableViewCellStyle, reuseIdentifier: String?, devInTask: HRDevsInTask) {
		self.sceneBind = devInTask
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		detailTextLabel?.textColor = UIColor.lightGrayColor()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func drawRect(rect: CGRect) {
		guard let device = sceneBind.device else {
			return
		}
		textLabel?.text = device.name
		if let relay = device as? HRRelayInBox {
			detailTextLabel?.text = "延时\(sceneBind.delayCode[0]/10).\(sceneBind.delayCode[0]%10)秒"
			if segSwitch == nil {
				segSwitch = newRelaySwitch(relay)
			}
			contentView.addSubview(segSwitch!)
			segSwitch!.alpha = editing ? 0:1
			segSwitch!.frame = CGRectMake(rect.width/2, 0, rect.width/2 - 5, frame.height*0.8)
			segSwitch!.cornerRadius = segSwitch!.bounds.height/2
			segSwitch!.center.y = contentView.bounds.height/2
			switch sceneBind.actBinds[Int(relay.relaySeq)] {
			case HRRelayRouteState.OFF.rawValue:
				segSwitch!.selectIndex(0, animated: false)
			case HRRelayRouteState.Reverse.rawValue:
				segSwitch!.selectIndex(1, animated: false)
			case HRRelayRouteState.ON.rawValue:
				segSwitch!.selectIndex(2, animated: false)
			default: break
			}
		} else if device.devType == HRDeviceType.CurtainControlUnit.rawValue || device.devType == HRDeviceType.Manipulator.rawValue {
			detailTextLabel?.text = "延时\(sceneBind.delayCode[0]/10).\(sceneBind.delayCode[0]%10)秒"
			if segSwitch == nil {
				segSwitch = newMotorSwitch()
			}
			contentView.addSubview(segSwitch!)
			segSwitch?.alpha = editing ? 0:1
			segSwitch!.frame = CGRectMake(rect.width/2, 0, rect.width/2 - 5, frame.height*0.8)
			segSwitch!.cornerRadius = segSwitch!.bounds.height/2
			segSwitch!.center.y = contentView.bounds.height/2
			switch sceneBind.actBinds[0] {
			case HRMotorCtrlStatus.Close.rawValue:
				segSwitch?.selectIndex(0, animated: false)
			case HRMotorCtrlStatus.Stop.rawValue:
				segSwitch?.selectIndex(1, animated: false)
			case HRMotorCtrlStatus.Open.rawValue:
				segSwitch?.selectIndex(2, animated: false)
			default: break
			}
		} else if device is HRApplianceApplyDev {
			if messageTextLabel == nil {
				messageTextLabel = UILabel(frame: CGRectMake(self.contentView.bounds.width*0.6, 0, self.contentView.bounds.width/2 - 25, self.contentView.bounds.height))
				messageTextLabel?.textColor = UIColor.lightGrayColor()
				messageTextLabel?.textAlignment = .Left
				messageTextLabel?.font = UIFont.systemFontOfSize(messageTextLabel!.font.pointSize - 1)
				self.contentView.addSubview(messageTextLabel!)
			}
			messageTextLabel?.alpha = editing ? 0:1
			detailTextLabel?.text = "延时\(sceneBind.delayCode[0]/10).\(sceneBind.delayCode[0]%10)秒"
			messageTextLabel?.text = sceneBind.infraredDecription
			segSwitch?.removeFromSuperview()
			rgbFieldView?.removeFromSuperview()
		} else if device is HRRGBLamp {
			if rgbFieldView == nil {
				rgbFieldView = UIView(frame: CGRectMake(self.contentView.bounds.width*0.6, 0, self.contentView.bounds.height * 0.8, self.contentView.bounds.height * 0.8))
				rgbFieldView?.center.y = self.contentView.bounds.midY
				rgbFieldView?.layer.borderColor  = UIColor(htmlColor: 0xFFDDDDDD).CGColor
                rgbFieldView?.layer.cornerRadius = rgbFieldView!.bounds.height / 2
				self.contentView.addSubview(rgbFieldView!)
			}
			if messageTextLabel == nil {
				messageTextLabel = UILabel(frame: CGRectMake(self.contentView.bounds.width*0.6, 0, self.contentView.bounds.width/2 - 25, self.contentView.bounds.height))
				messageTextLabel?.textColor = UIColor.lightGrayColor()
				messageTextLabel?.textAlignment = .Left
				messageTextLabel?.font = UIFont.systemFontOfSize(messageTextLabel!.font.pointSize - 1)
				self.contentView.addSubview(messageTextLabel!)
			}
			detailTextLabel?.text = "延时\(sceneBind.delayCode[0]/10).\(sceneBind.delayCode[0]%10)秒"
			if let description = sceneBind.rgbDescription {
				messageTextLabel?.hidden = false
				rgbFieldView?.hidden = true
				messageTextLabel?.text = description
			} else {
				let R = Int(sceneBind.actBinds[1])
				let G = Int(sceneBind.actBinds[2])
				let B = Int(sceneBind.actBinds[3])
				rgbFieldView?.layer.backgroundColor = UIColor(R: R, G: G, B: B, alpha: 1).CGColor
				if R + G + B > 255*3-30 {
					rgbFieldView?.layer.borderWidth = 0.5
				} else {
					rgbFieldView?.layer.borderWidth = 0
				}
				rgbFieldView?.alpha = editing ? 0:1
			}
			segSwitch?.removeFromSuperview()
		} else if device is HRScene {
			detailTextLabel?.text = "延时\(sceneBind.delayCode[0]/10).\(sceneBind.delayCode[0]%10)秒"
			segSwitch?.removeFromSuperview()
			messageTextLabel?.removeFromSuperview()
			rgbFieldView?.removeFromSuperview()
		} else {
			detailTextLabel?.removeFromSuperview()
			segSwitch?.removeFromSuperview()
			messageTextLabel?.removeFromSuperview()
			rgbFieldView?.removeFromSuperview()
		}
	}
	
	private func newRelaySwitch(relay:HRRelayInBox) -> DVSwitch {
		let seg = DVSwitch(stringsArray: ["关", "翻转", "开"])
		seg.enabled = enabled
		seg.setPressedHandler({
			(index) in
			if let relay = self.sceneBind.device as? HRRelayInBox {
				switch index {
				case 0:
					self.sceneBind.actBinds[Int(relay.relaySeq)]
						= HRRelayRouteState.OFF.rawValue
				case 1:
					self.sceneBind.actBinds[Int(relay.relaySeq)]
						= HRRelayRouteState.Reverse.rawValue
				case 2:
					self.sceneBind.actBinds[Int(relay.relaySeq)]
						= HRRelayRouteState.ON.rawValue
				default: break
				}
			}
		})
		return seg
	}
	
	private func newMotorSwitch() -> DVSwitch {
		let seg = DVSwitch(stringsArray: ["关", "暂停", "开"])
		seg.enabled = enabled
		seg.setPressedHandler({
			(index) in
			switch index {
			case 0:
				self.sceneBind.actBinds[0] = HRMotorCtrlStatus.Close.rawValue
			case 1:
				self.sceneBind.actBinds[0] = HRMotorCtrlStatus.Stop.rawValue
			default:
				self.sceneBind.actBinds[0] = HRMotorCtrlStatus.Open.rawValue
			}
		})
		return seg
	}

	
	override func setEditing(editing: Bool, animated: Bool) {
		if !self.editing && editing {
			//如果当前没有编辑，接下来准备要编辑，false -> true, 则隐藏segSwitch
			UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn, animations: {
				self.segSwitch?.alpha = 0
				self.rgbFieldView?.alpha = 0
				self.messageTextLabel?.alpha = 0
				}, completion: nil)
		} else if self.editing && !editing {
			//如果当前在编辑，接下来准备要退出编辑，true -> false, 则显示segSwitch
			UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn, animations: {
				self.segSwitch?.alpha = 1
				self.rgbFieldView?.alpha = 1
				self.messageTextLabel?.alpha = 1
				}, completion: nil)
		} else {
			//其他情况不用理
			super.setEditing(editing, animated: animated)
			return
		}
		super.setEditing(editing, animated: animated)
	}
	
	func free() {
		segSwitch?.setPressedHandler(nil)
		segSwitch?.removeFromSuperview()
		segSwitch = nil
	}
}
