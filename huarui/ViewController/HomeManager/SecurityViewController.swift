//
//  SecurityViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/21.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 安防界面
class SecurityViewController: BaseManagerViewController, UICollectionViewDelegate, UICollectionViewDataSource, HR8000HelperDelegate, UIAlertViewDelegate {

    private var collection: UICollectionView!
    
    private var securDevs: [HRDevice]!
	private var _currentSlectedDevice: HRDevice?
    //没有情景的时候提示“无设备”的view
    private var noDevicesTipsView: UIView?
	
    override func viewDidLoad() {
		super.viewDidLoad()
        let navBarHeight = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        let tabHeight = tabBarController!.tabBar.frame.height + navBarHeight
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(5, 10, tabHeight + 10, 10)
        layout.itemSize = CGSizeMake(95, 115)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        collection = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        self.view.addSubview(collection)
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collection.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
        collection.backgroundColor = UIColor.clearColor()
        collection.scrollIndicatorInsets = UIEdgeInsetsMake(2, 0, tabHeight, 1)
        collection.dataSource = self
        collection.delegate   = self
        initComponent()
		
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(SecurityViewController.collectionViewWillRefresh))
		
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		
		collection.header = header
        
    }
    
	override func viewWillAppear(animated: Bool) {
		self.title = "安防"
		super.viewWillAppear(animated) 
    }
    
    override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate    = self
        collection.reloadData()

    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

	}
    
    
    
    
    //自己写的一个方法 输入不同的类型返回不同的数组
    
    
    private func getMyLockFormDatabase(type:HRDeviceType) -> [HRDevice]{
    
        let locks = HRDatabase.shareInstance().getDevicesOfType(type)
        
        
        print(locks)

        return locks!
        
        
        
    }
    
    
    
	
	private func getSecurDevsFromDatabase() -> [HRDevice] {
        //斌 门锁相关 这里 获取门锁的数据 加载在UI上
        
        //斌 门锁相关 判断 设备类型 返回一个数组
        
         if let smartLock = HRDatabase.shareInstance().getDevicesOfType(.DoorLock) as? [HRDoorLock] {
            
            print("查询到了一般锁")
            
            return smartLock
            
        }

		if let locks = HRDatabase.shareInstance().getDevicesOfType(.GaoDunDoor) as? [HRSmartDoor] {
            
            print("查询到了gaudun的锁")
            
			return locks
		}
        
        
            
        
        
        else {
            
            
            DDLogWarn("没有锁，来到这里")
			return [HRDoorLock]()
		}
	}
	
	private func getTipView(text: String) -> UIView{
		let label = UILabel()
		let str = NSString(string: text)
		let attr = [NSFontAttributeName: UIFont.systemFontOfSize(30)]
		let size = str.sizeWithAttributes(attr)
		
		label.frame = CGRectMake(0, 0, size.width, size.height )
		label.text = text
		label.textColor = UIColor.lightGrayColor()
		label.font = UIFont.systemFontOfSize(30)
		label.textAlignment = NSTextAlignment.Center
		
		return label
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    /**显示组件*/
    private func initComponent(){
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collection.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
        collection.delegate = self
        collection.dataSource = self
        
    }

//MARK: - CollectionView
	
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		//securDevs =  getSecurDevsFromDatabase()
        
    let GaodunArray   = getMyLockFormDatabase(HRDeviceType.GaoDunDoor)
        
    let oldArray      = getMyLockFormDatabase(HRDeviceType.DoorLock)
        
        
    let allLockArray = GaodunArray + oldArray
        
        securDevs = allLockArray
        
        
        
      
        if securDevs.count == 0 {
            if self.noDevicesTipsView == nil {
				self.noDevicesTipsView = getTipView("无设备")
				self.noDevicesTipsView?.center = self.view.center
                self.view.addSubview(noDevicesTipsView!)
            }
        } else {
            self.noDevicesTipsView?.removeFromSuperview()
            self.noDevicesTipsView = nil
        }
        return securDevs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell
        cell.device = securDevs[indexPath.row]
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
        //增加单击手势
        let tapGestrue = UITapGestureRecognizer(target: self, action: #selector(SecurityViewController.onCellTapClicked(_:)))
        cell.addGestureRecognizer(tapGestrue)
        //增加长按手势
        let longGestrue = UILongPressGestureRecognizer(target: self, action: #selector(SecurityViewController.onCellLongClicked(_:)))
        cell.addGestureRecognizer(longGestrue)
        
        return cell
    }
	
//MARK: - UI事件
	
	///下拉刷新
	func collectionViewWillRefresh() {
		HR8000Service.shareInstance().queryDevice(HRDeviceType.DoorLock)
        
        
        //下拉刷新加一个高盾锁的查询 门锁相关 斌
        HR8000Service.shareInstance().queryDevice(HRDeviceType.GaoDunDoor)

		///3秒之后停止refreshing
		runOnMainQueueDelay(3000, block: {
			self.collection.header.endRefreshing()
		})
	}
	
    func onCellTapClicked(gesture: UITapGestureRecognizer){
        if gesture.view == nil || !(gesture.view is DeviceCollectionViewCell){
            return
        }
        let device = (gesture.view as! DeviceCollectionViewCell).device
        if device == nil{
            return
        }
		runOnGlobalQueue({
			DeviceUseFrequency.addDevice(HRDatabase.shareInstance().acount.userName, device: device)
		})
        switch device!.devType{
        case HRDeviceType.DoorLock.rawValue:
            self.performSegueWithIdentifier("showDoorLockViewController", sender: device!)
         
            
        //门锁相关 这里要加一个高盾锁的类型 
            
        case HRDeviceType.GaoDunDoor.rawValue:
            print("以后要")
            
            //KVNProgress.showErrorWithStatus("在处理中，这个是新的锁(\(device.devType))")

            self.performSegueWithIdentifier("showDoorLockViewController", sender: device!)
            
            
		default:
			KVNProgress.showErrorWithStatus("暂时不支持该设备(\(device.devType))")
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

    // MARK: - HR8000HelperDelegate
    
    ///查询设备
    func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]) {
        switch device.devType {
        case HRDeviceType.DoorLock.rawValue:
            print("这里有什么用0")

        case HRDeviceType.GaoDunDoor.rawValue:
            print("下拉刷新看到高盾所")
            //数组比较  如果不相等 就重新 刷新
            if !getSecurDevsFromDatabase().elementsEqual(self.securDevs) {
                print("这里有什么用1")
                collection.reloadData()
            }
        default: break
        }
	}
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		self.collection.header.endRefreshing()
		collection.reloadData()
	}
	
	func hr8000Helper(didDeleteDevice device: HRDevice) {
		switch device.devType {
		case HRDeviceType.DoorLock.rawValue:
			
			for i in 0..<self.securDevs.count {
				if device.devAddr == self.securDevs[i].devAddr {
					self.collection.deleteItemsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)])
					break
				}
			}
		default: break
		}
	}

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDoorLockViewController"{
            let controller = segue.destinationViewController as! DoorLockViewController
            controller.device = sender as! HRDevice
        }
    }
}
