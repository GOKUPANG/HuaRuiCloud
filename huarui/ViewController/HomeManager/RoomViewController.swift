//
//  RoomViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/21.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 房间管理
//FloorManagerViewDelegate这个代理有三个方法，是为了获取房间 和 楼层信息 斌注释

@available(iOS 8.0, *)
class RoomViewController: BaseManagerViewController,FloorManagerViewDelegate,UICollectionViewDelegate, UICollectionViewDataSource,UIAlertViewDelegate, HRRelayBaseDeviceDelegate, HR8000HelperDelegate {
    
    private var managerView: FloorManagerView!
    private var noDevicesTipsView : UIView?
	private var currentDevices = [HRDevice]()
	private var isMenuShow = false
	
	
	//MARK: - ViewController
	
	
    override func viewDidLoad() {
		super.viewDidLoad()
        
        
        addFloorManagerView()
        //调用下面的addFloorManagerView方法，设置界面,斌注释
    }
    
	override func viewWillAppear(animated: Bool) {
		self.title = "房间管理"
        super.viewWillAppear(animated)
		//让自己成为relayBaseDeviceDelegate的代理，而这个代理负责操纵继电器的状态，实现开灯关灯 斌注释
        HRProcessCenter.shareInstance().delegates.relayBaseDeviceDelegate = self
        //成为hr8000HelperDelegate 的代理 斌注释
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate    = self
        
        //确认代理都已经设置好了 斌注释
        managerView.reloadData() 
    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	} 
	
// MARK: - 界面设置
	
    private func addFloorManagerView(){
        managerView = FloorManagerView()
        let bottomH = tabBarController!.tabBar.frame.height
		let navBarH = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        managerView.frame = CGRectMake(0, 0, self.view.frame.width, view.frame.height - bottomH - navBarH)
        managerView.delegate = self
        
        
        
        //set managerView style
        managerView.titleHeight = 36//这个是
        
        //managerView.titleHeight = 60
        managerView.titleColorNormal = UIColor.whiteColor()
        managerView.titleColorSelected = APP.param.selectedColor
        managerView.scrBgColor = APP.param.themeColor
        
        view.addSubview(managerView)
    }
	
	//获取所有楼层名
	func floorManagerViewGetFloors() -> [UInt16 : String] {
        //[UInt16 : String]是一个字典 key是UInt16 ，Value是String 斌注释
		var floorIdNames = [UInt16 : String]()
		let floors = HRDatabase.shareInstance().floors
		if floors.count == 0 {
			if self.noDevicesTipsView == nil {
            
               // let alertNoRoom = UIAlertController (title: "提示", message: "查询设备失败", preferredStyle:)
                let alertController = UIAlertController(title: "系统提示",
                                                        message: "无法查询到设备", preferredStyle: .Alert)
                //let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
                let okAction = UIAlertAction(title: "好的", style: .Default,
                                             handler: {
                                                action in
                                             //   print("点击了确定")
                })
               // alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                
                
                
                
                
				self.noDevicesTipsView = noDeviceView("无房间")
				self.noDevicesTipsView?.center = view.center
				self.view.addSubview(noDevicesTipsView!)
			}
		} else {
			self.noDevicesTipsView?.removeFromSuperview()
			self.noDevicesTipsView = nil
			
			for floor in floors {
				floorIdNames[floor.id] = floor.name
			}
		}
		return floorIdNames
	}
	
	//获取指定楼层的房间名
	func floorManagerView(floorManagerView: FloorManagerView, roomsForFloor floorId: UInt16, floorName: String) -> [UInt16 : String] {
		var roomIdNames = [UInt16 : String]()
		for floor in HRDatabase.shareInstance().floors where floor.id == floorId {
			if floor.roomInfos.count == 0 {
				return [0: "(此楼层没有房间)"]
			}
			for room in floor.roomInfos {
				roomIdNames[room.id] = room.name
			}
		}
		return roomIdNames
	}
	
	//获取房间View，每个房间一个CollectionView
	func floorManagerView(floorManagerView: FloorManagerView, viewForRoom roomId: UInt16, roomName: String, floorId: UInt16, floorName: String) -> UIView {
        //获得
		currentDevices = HRDatabase.shareInstance().getDevicesFromRoom(floorId, roomId: roomId)
		if currentDevices.count == 0 {
			return noDeviceView("此房间无设备")
		}
		return createRoomView(floorId, roomId: roomId)
	}
	
	//创建房间View
    func createRoomView(floorId: UInt16, roomId: UInt16) -> UIView {
        let topH = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        let bottomH = tabBarController!.tabBar.frame.height
        let frm = CGRectMake(0, managerView.titleHeight + topH, view.frame.width, view.frame.height - topH - managerView.titleHeight - bottomH)
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(5, 10, bottomH + 30, 10)
        layout.itemSize = CGSizeMake(95, 115)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let collection = UICollectionView(frame: frm, collectionViewLayout: layout)
        collection.dataSource = self
        collection.delegate   = self
        collection.tag        = roomIdToTag(roomId)
        collection.backgroundColor = UIColor.clearColor()
		collection.scrollIndicatorInsets = UIEdgeInsets(top: 2, left: 0, bottom: 5, right: 0)
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collection.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
		
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(RoomViewController.collectionViewWillRefresh))
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		collection.header = header
		
        return collection
	}
	
	//MARK: - 每个房间一个CollectionView
	
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		let floorId = managerView.currentFloorId
		let roomId  = tagToRoomId(collectionView.tag)
        //获得这个房间的设备数组，数组的长度就是collectionView的item数量 斌注释
        //这个方法根据参数楼层的id。房间的id可以定位到具体的那个房间，然后得到具体的那个房间的设备数组 斌注释
		currentDevices = HRDatabase.shareInstance().getDevicesFromRoom(floorId, roomId: roomId)
		return currentDevices.count
	}
	
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell

        if currentDevices.count == 0 {
            cell.deviceLabel.text = "(nil)"
            return cell
        }
        let device = currentDevices[indexPath.row]
        cell.device = device
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
        //增加单击手势
        let tapGestrue = UITapGestureRecognizer(target: self, action: #selector(RoomViewController.onCellTapClicked(_:)))
        cell.addGestureRecognizer(tapGestrue)
        //增加长按手势
        let longGestrue = UILongPressGestureRecognizer(target: self, action: #selector(RoomViewController.onCellLongClicked(_:)))
        cell.addGestureRecognizer(longGestrue)
        
        return cell
    }
	
	private func getRoomView(floorId: UInt16, roomId: UInt16) -> UICollectionView? {
		return managerView.getRoomViewWithTag(roomIdToTag(roomId)) as? UICollectionView
	}
	
	func noDeviceView(msg: String) -> UIView {
		let label = UILabel()
		let str = NSString(string: msg)
		let attr = [NSFontAttributeName: UIFont.systemFontOfSize(30)]
		let size = str.sizeWithAttributes(attr)
		
		label.frame = CGRectMake(50, 100, size.width, size.height )
		label.text = msg
		label.textColor = UIColor.lightGrayColor()
		label.font = UIFont.systemFontOfSize(30)
		label.textAlignment = NSTextAlignment.Center
		
		return label
	}
	
	private func roomIdToTag(roomId: UInt16) -> Int {
		return Int(roomId + 100)
	}
	
	private func tagToRoomId(tag: Int) -> UInt16 {
		return UInt16(tag - 100)
	}
	
//MARK: - UI事件
	
	func floorManagerView(floorManagerView: FloorManagerView, didSelectedRoom roomId: UInt16, roomName: String, floorId: UInt16, floorName: String) {
		currentDevices = HRDatabase.shareInstance().getDevicesFromRoom(floorId, roomId: roomId)
	}
	
	///下拉刷新
	func collectionViewWillRefresh() {
        //获得所有类型的设备
		HR8000Service.shareInstance().queryAllDevice()
	}
    
    func onCellTapClicked(gesture: UITapGestureRecognizer){
        if gesture.view == nil && !(gesture.view is DeviceCollectionViewCell){
            return
        }
        let device = (gesture.view as! DeviceCollectionViewCell).device
        if device == nil{
            return
        }
        
        //在常用设备中添加一个设备，存进数据库里面 斌注释
		runOnGlobalQueue({
			DeviceUseFrequency.addDevice(HRDatabase.shareInstance().acount.userName, device: device)
		})
        switch device!.devType {
        case HRDeviceType.relayTypes(): //点击的是继电器设备
            //KVNProgress是第三方库 ，显示hud 斌注释
            
           // print("开灯关灯")
            KVNProgress.showWithStatus("通信中...")
            //在这里进入控制继电器开关的实现，一层一层的嵌套 斌注释
            //这里的意思继电器操作把开关的状态取反(Reverse)本来是开的那就把它关闭，本来是关闭的那就把它打开 斌注释
            (device! as! HRRelayInBox).operate(.Reverse,
                result: { (error) in
                    if let err = error {
                        KVNProgress.showErrorWithStatus("失败：\(err.domain)")
                    } else {
                        KVNProgress.dismiss()
                    }
			})
		case HRDeviceType.RGBLamp.rawValue:
			self.performSegueWithIdentifier("showRGBCtrlViewController", sender: device)
        case HRDeviceType.CurtainControlUnit.rawValue: //点击的是窗帘控制器
            self.performSegueWithIdentifier("showCurtainCtrl", sender: device)
        case HRDeviceType.ApplyDevice.rawValue: //应用设备
            let apply = device as! HRApplianceApplyDev
            switch apply.appDevType {
			case HRAppDeviceType.AirCtrl.rawValue: //空调
				let controller = AirCtrlViewController()
				controller.appDevice = apply
				self.navigationController?.pushViewController(controller, animated: true)
			case HRAppDeviceType.TV.rawValue:       //电视机
				let controller = TVCtrlViewController()
				controller.appDevice = apply
				self.navigationController?.pushViewController(controller, animated: true)
            case HRAppDeviceType.STB.rawValue:      //机顶盒
                //                self.performSegueWithIdentifier("showAirCtrl", sender: apply)
                break
            default:
                break
            }
        case HRDeviceType.SmartBed.rawValue:
            self.performSegueWithIdentifier("showSmartBedViewController", sender: device)
        case HRDeviceType.SolarSensor.rawValue:
            self.performSegueWithIdentifier("showSolarSensorViewController", sender: device)
        case HRDeviceType.GasSensor.rawValue:
            self.performSegueWithIdentifier("showGasSensorViewController", sender: device)
        case HRDeviceType.Manipulator.rawValue:
            self.performSegueWithIdentifier("showManipulatorViewController", sender: device)
		default:
			KVNProgress.showErrorWithStatus("暂时不支持该设备(\(device.devType))")
            Log.warn("点击的设备\(device.devType)暂不支持。")
            break
        }
    }
    
	func onCellLongClicked(gestrue: UILongPressGestureRecognizer){
		if gestrue.view == nil || !(gestrue.view is DeviceCollectionViewCell) {
			return
		}
		let cell = gestrue.view! as! DeviceCollectionViewCell
		switch gestrue.state {
		case .Began:
			cell.selected = true
			if self.tabBarController?.tabBar == nil || currentDeviceModel == .iPad {
				cell.longClickedHandler(showInView: self.view, navigationController: self.navigationController)
			} else {
				cell.longClickedHandler(showInView: self.tabBarController!.tabBar, navigationController: self.navigationController)
			}
		case .Ended:
			cell.selected = false
		default:
			break
		}
	}

	
// MARK: - HRRelayBaseDeviceDelegate代理
	
	func relayBaseDevice(relayBaseDevice: HRRelayComplexes) {
		for relay in relayBaseDevice.relays {
			if let collectView = self.getRoomView(relay.insFloorID, roomId: relay.insRoomID) {
				if let cell = collectView.hrGetCellWithDevice(relay) {
					cell.updateSatus(true)
				} else {
                    Log.warn("在该房间中找不到\(relay.elecName)")
				}
			}else {
                Log.warn("找不到\"\(relay.elecName)\"所在的房间。floorId=\(relay.insFloorID), roomId=\(relay.insRoomID)")
			}
		}
	}
	
//MARK: - HR8000HelperDelegate代理
	
	func hr8000Helper(commitDeviceState device: HRDevice) {
		if let relayComplexes = device as? HRRelayComplexes {
			self.relayBaseDevice(relayComplexes)
		}
	}
	
    func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		managerView.reloadData()
    }
	
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		managerView.reloadData()
	}
    
    
//MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == nil {
            return
        }
        switch segue.identifier! {
        case "showCurtainCtrl":
            let curtainCtrller = segue.destinationViewController as! CurtainCtrlViewController
            curtainCtrller.curtainDev = sender as? HRCurtainCtrlDev
        case "showAirCtrl" :
            let airCtrller = segue.destinationViewController as! AirCtrlViewController
            airCtrller.appDevice = sender as? HRApplianceApplyDev
        case "showTVCtrl" :
            let tvCtrller = segue.destinationViewController as! TVCtrlViewController
            tvCtrller.appDevice = sender as? HRApplianceApplyDev
        case "showSolarSensorViewController":
            let controller = segue.destinationViewController as! SolarSensorViewController
            controller.solarDev = sender as? HRSolarSensor
        case "showGasSensorViewController":
            let controller = segue.destinationViewController as! GasSensorViewController
            controller.gasDev = sender as? HRGasSensor
        case "showManipulatorViewController":
            let controller = segue.destinationViewController as! ManipulatorViewController
            controller.manipDev = sender as? HRManipulator
		case "showRegisterDeviceViewController":
			let controller = segue.destinationViewController as! RegisterDeviceViewController
			controller.floorName = managerView.currentFloorName
			controller.roomName  = managerView.currentRoomName
		case "showEditRelayBoxViewController":
			let controller = segue.destinationViewController as!
			EditRelayBoxViewController
			let relay = sender as! HRRelayInBox
			controller.relayBox = relay.relayBox
			controller.routerEnable = [
				relay.relaySeq == 0,
				relay.relaySeq == 1,
				relay.relaySeq == 2,
				relay.relaySeq == 3,
			]
		case "showRGBCtrlViewController":
			let controller = segue.destinationViewController as! RGBCtrlViewController
			controller.rgbDevice = sender as! HRRGBLamp
			
//        case "showSmartBedViewController":
//            let controller = segue.destinationViewController as! SmartBedViewController
//            controller.manipDev = sender as? HRManipulator
        default: break
        }
    }
    
}

