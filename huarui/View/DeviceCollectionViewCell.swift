//
//  DeviceCollectionViewCell.swift
//  huarui
//
//  Created by sswukang on 15/1/22.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/**
*  设备管理里面的一个cell
*/
class DeviceCollectionViewCell: UICollectionViewCell, UIActionSheetDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak private var deviceImg: UIImageView!
    @IBOutlet weak var deviceLabel: UILabel!
    
    private var __hightlighted: Bool = false
	
	//请求删除的AlertView的tag
	private let tagAlertViewDelete = 100
    
    override var highlighted: Bool {
        didSet{
            //如果不允许图片高亮，则立即返回
            if !shouldImageHighted { return }
            if highlighted && !__hightlighted { //点击的效果
                self.__hightlighted = true
                if let dev = device {
                    UIView.transitionWithView(self.deviceImg, duration: 0.1, options: [UIViewAnimationOptions.TransitionCrossDissolve, UIViewAnimationOptions.CurveEaseOut], animations: {
                        self.deviceImg.image = UIImage(named: "\(dev.iconName)_clicked")
                        }, completion: {
                            (comp) in
                            UIView.transitionWithView(self.deviceImg, duration: 0.5, options: [UIViewAnimationOptions.TransitionCrossDissolve, UIViewAnimationOptions.CurveEaseInOut], animations: {
                                self.deviceImg.image = UIImage(named: dev.iconName)
                                }, completion: nil)
                    })
                }
            }
            if !highlighted && __hightlighted { //释放的效果
                self.__hightlighted = false
                
            }
        }
    }
    
    private var _oldImageName: String?
    private var _animated: Bool = false
    
    var device: HRDevice! {
        didSet{
            deviceLabel.text = device.name
            let newImageName = device.iconName
            if _oldImageName != newImageName {
                setCellImage(newImageName, animated: _animated)
            }
            _oldImageName = newImageName
        }
	}
	weak var navigationController: UINavigationController?
	///是否允许图片高亮
	var shouldImageHighted: Bool = false
	
	
	//MARK: - method
	
    func setDeviceWithAnimation(device: HRDevice, animated: Bool) {
        self._animated = animated
        self.device = device
        self._animated = false
    }
	
	func updateSatus(animated: Bool) {
		deviceLabel.text = device.name
		setCellImage(device.iconName, animated: animated)
	}
	
    private func setCellImage(imgName: String, animated: Bool ) {
        if animated {
            UIView.transitionWithView(deviceImg, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.deviceImg.image = UIImage(named: imgName)
                }, completion: nil)
            
        } else {
            self.deviceImg.image = UIImage(named: imgName)
        }
    }
	
//MARK: - Cell的事件响应
	
	/**
	长按cell时的响应方法
	
	- parameter view:: 给UIActionSheet显示的view
	- parameter navigationController: 导航Controller，用于跳转到其他vc
	*/
	func longClickedHandler(showInView view: UIView, navigationController: UINavigationController?) {
		self.navigationController = navigationController
		let sheet = UIActionSheet(
			title: device.name, delegate: self,
			cancelButtonTitle: nil,
			destructiveButtonTitle: nil
		)
		let editPermission = HRDatabase.isEditPermission
		switch device.devType {
		case HRDeviceType.relayTypes():
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		case HRDeviceType.DoorLock.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
				sheet.addButtonWithTitle("修改密码")
			}
		case HRDeviceType.Scene.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
				sheet.addButtonWithTitle("删除")
				sheet.destructiveButtonIndex = sheet.numberOfButtons - 1
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		case HRDeviceType.ApplyDevice.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
				sheet.addButtonWithTitle("红外学习")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		case HRDeviceType.Task.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
				sheet.addButtonWithTitle("删除")
				sheet.destructiveButtonIndex = sheet.numberOfButtons - 1
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		case HRDeviceType.ScenePanel.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		case HRDeviceType.SolarSensor.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
			sheet.addButtonWithTitle("光照动作值")
			sheet.addButtonWithTitle("动作值与设备绑定")
		case HRDeviceType.GasSensor.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
			sheet.addButtonWithTitle("可燃气动作值")
			sheet.addButtonWithTitle("动作值与设备绑定")
		case HRDeviceType.HumiditySensor.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
			sheet.addButtonWithTitle("湿敏动作值")
			sheet.addButtonWithTitle("动作值与设备绑定")
		case HRDeviceType.AirQualitySensor.rawValue:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
			sheet.addButtonWithTitle("温湿度动作值")
			sheet.addButtonWithTitle("动作值与设备绑定")
		default:
			if editPermission {
				sheet.addButtonWithTitle("编辑")
			} else {
				sheet.addButtonWithTitle("查看信息")
			}
		}
		sheet.addButtonWithTitle("取消")
		sheet.cancelButtonIndex = sheet.numberOfButtons - 1
		
		if view is UITabBar {
			sheet.showFromTabBar(view as! UITabBar)
		} else {
			sheet.showInView(view)
		}
	}
	
	func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
		switch actionSheet.buttonTitleAtIndex(buttonIndex)! {
		case "删除":
			switch device.devType {
			case HRDeviceType.relayTypes():
				var msgstr = "删除“\(device.name)”同时也会将"
				let relayBox = (device as! HRRelayInBox).relayBox
				for relay in relayBox.relays {
					if relay === device {
						continue
					}
					msgstr += "“\(relay.name)”、"
				}
				msgstr.removeAtIndex(msgstr.endIndex.predecessor())
				msgstr += "一起删除!\n您确定删除它们吗？"
				let delAlert = UIAlertView(title: "提示", message: msgstr, delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
				delAlert.tag = tagAlertViewDelete
				delAlert.show()
			default:
				let delAlert = UIAlertView(title: "提示", message: "您确定要删除“\(device.name)”吗？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
				delAlert.tag = tagAlertViewDelete
				delAlert.show()
			}
		case "编辑", "查看信息":
			switch device.devType {
			case HRDeviceType.relayTypes():
				let controller = EditRelayBoxViewController()
				let relay = device as! HRRelayInBox
				controller.relayBox = relay.relayBox
				controller.routerEnable = [
					relay.relaySeq == 0,
					relay.relaySeq == 1,
					relay.relaySeq == 2,
					relay.relaySeq == 3,
				]
				navigationController?.pushViewController(controller, animated: true)
			case HRDeviceType.ApplyDevice.rawValue:
				//编辑应用设备
				let vc = CreateEditAppDeviceViewController()
				vc.title = "编辑\(device.name)"
				vc.isCreate = false
				let appDev = device as! HRApplianceApplyDev
				vc.appDevice = appDev
				navigationController?.pushViewController(vc, animated: true)
				
			case HRDeviceType.Scene.rawValue:
				let vc = CreateSceneViewController()
				vc.sceneDevice = device as? HRScene
				navigationController?.pushViewController(vc, animated: true)
			case HRDeviceType.Task.rawValue:
				let vc = CreateEditTaskViewController()
				vc.taskDevice = device as? HRTask
				navigationController?.pushViewController(vc, animated: true)
			case HRDeviceType.ScenePanel.rawValue:
				let vc = EditScenePanelViewController()
				vc.scenePanel = device as? HRScenePanel
				navigationController?.pushViewController(vc, animated: true)
			default:
				let vc = EditDeviceInfoViewController()
				vc.device = device
				navigationController?.pushViewController(vc, animated: true)
			}
		case "红外学习":
			if (device as? HRApplianceApplyDev)?.appDevType == HRAppDeviceType.AirCtrl.rawValue {
				let controller = LearningInfraredViewController()
				controller.appDevice = device as? HRApplianceApplyDev
				navigationController?.pushViewController(controller, animated: true)
			} else if (device as? HRApplianceApplyDev)?.appDevType == HRAppDeviceType.TV.rawValue {
				let controller = TVCtrlViewController()
				controller.todo = SHARETODO_LEARNING_TV_CTRL
				controller.appDevice = device as? HRApplianceApplyDev
				navigationController?.pushViewController(controller, animated: true)
			}
		case "修改密码":
			let controller = DoorLockChangePasswdViewController()
			controller.lock = device as? HRDoorLock
			navigationController?.pushViewController(controller, animated: true)
		case "光照动作值","可燃气动作值","湿敏动作值","温湿度动作值":
			let controller = EditSensorActionsViewController()
			controller.sensor = device as? HRSensor
			navigationController?.pushViewController(controller, animated: true)
		case "动作值与设备绑定":
			let controller = EditSensorBindsViewController()
			controller.sensor = device as? HRSensor
			navigationController?.pushViewController(controller, animated: true)
		default: break
		}
	
	}
	
	func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
		if device == nil || buttonIndex == alertView.cancelButtonIndex {
			return
		}
		switch alertView.tag {
		case tagAlertViewDelete:
			KVNProgress.showWithStatus("正在删除...")
			device.deleteFromRemote({ (error) in
				if let err = error {
					KVNProgress.showErrorWithStatus(err.domain)
				} else {
					KVNProgress.showSuccessWithStatus("删除成功!")
				}
			})
			break
		default: break
		}
	}
}

//MARK: - extension UICollectionView

extension UICollectionView {
	
	
    func hrGetCellWithDevice(relay: HRRelayInBox) -> DeviceCollectionViewCell? {
		for section in 0..<self.numberOfSections() {
			for row in 0..<self.numberOfItemsInSection(section) {
				let cell = cellForItemAtIndexPath(NSIndexPath(forRow: row, inSection: section))
				if cell is DeviceCollectionViewCell &&
					(cell as! DeviceCollectionViewCell).device is HRRelayInBox {
						let devCell = cell as! DeviceCollectionViewCell
						let device  = devCell.device as! HRRelayInBox
						if devCell.device?.devAddr == relay.devAddr &&
							devCell.device?.hostAddr == relay.hostAddr &&
							device.relaySeq == relay.relaySeq{
								return devCell
						}
				}
			}
		}
        return nil
    }
}


