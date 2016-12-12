//
//  ScenePanelViewController.swift
//  huarui
//
//  Created by sswukang on 15/7/14.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class ScenePanelViewController: BaseManagerViewController, UICollectionViewDataSource, UICollectionViewDelegate, HR8000HelperDelegate {

    private var collectionView: UICollectionView!
    private var noDevicesTipsView: UIView!
    
    private var scenePanels = [HRScenePanel]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		
		
        
		let navBarHeight = navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
		var tabHeight = navBarHeight
		if let tabH = tabBarController?.tabBar.frame.height {
			tabHeight += tabH
		}
		let layout = UICollectionViewFlowLayout()
		layout.sectionInset = UIEdgeInsetsMake(5, 10, tabHeight + 5, 10)
		layout.itemSize = CGSizeMake(95, 115)
		layout.minimumLineSpacing = 5
		layout.minimumInteritemSpacing = 5
		
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        self.view.addSubview(collectionView)
        let cellNib = UINib(nibName: "DeviceCollectionViewCell", bundle: nil)
        collectionView.registerNib(cellNib, forCellWithReuseIdentifier: "deviceCell")
        collectionView.backgroundColor = UIColor.clearColor()
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, 0, tabHeight, 1)
        collectionView.dataSource = self
        collectionView.delegate   = self
		
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(ScenePanelViewController.collectionViewWillRefresh))
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		
		collectionView.header = header
    }
    
	override func viewWillAppear(animated: Bool) {
		self.title = "情景面板"
		super.viewWillAppear(animated)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
		collectionView.reloadData()
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	private func getScenePanelsFromDatabase() -> [HRScenePanel] {
		if let panels = HRDatabase.shareInstance().getDevicesOfType(.ScenePanel) as? [HRScenePanel] {
			return panels
		}
		return [HRScenePanel]()
	}
	

//MARK: - CollectionView
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        scenePanels = getScenePanelsFromDatabase()
        if scenePanels.count == 0 {
			if self.noDevicesTipsView == nil {
				self.noDevicesTipsView = getTipView("无情景面板")
				self.noDevicesTipsView?.center = self.view.center
                self.view.addSubview(noDevicesTipsView!)
            }
        } else {
            self.noDevicesTipsView?.removeFromSuperview()
            self.noDevicesTipsView = nil
        }
        return scenePanels.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell
        cell.device = scenePanels[indexPath.row]
        cell.shouldImageHighted = true
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
		cell.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(ScenePanelViewController.onCellLongPressed(_:))))
        return cell
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
	
	
	//MARK: - UI事件
	@objc private func onCellLongPressed(gesture: UILongPressGestureRecognizer){
		if gesture.state == .Began {
			let cell = gesture.view as? DeviceCollectionViewCell
			if self.tabBarController?.tabBar == nil || currentDeviceModel == .iPad {
				cell?.longClickedHandler(showInView: self.view, navigationController: self.navigationController)
			} else {
				cell?.longClickedHandler(showInView: self.tabBarController!.tabBar, navigationController: self.navigationController)
			}
		}
	}
	
	///下拉刷新
	func collectionViewWillRefresh() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ScenePanelViewController.onQueryDeviceDone(_:)), name: kNotificationQueryDone, object: nil)
		
		HR8000Service.shareInstance().queryDevice(HRDeviceType.ScenePanel)
		///3秒之后停止refreshing
		runOnMainQueueDelay(3000, block: {
			self.collectionView.header.endRefreshing()
		})
	}
	
	func onQueryDeviceDone(notification: NSNotification ){
		NSNotificationCenter.defaultCenter().removeObserver(self, name: kNotificationQueryDone, object: nil)
		self.collectionView.header.endRefreshing()
	}
	
	func onAddBarButtonClicked(button: UIBarButtonItem) {
		let controller = RegisterDeviceViewController()
		self.navigationController?.pushViewController(controller, animated: true)
	}
	
	
	//MARK: - HR8000HelperDelegate
	
	func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]) {
		switch device.devType {
		case HRDeviceType.Scene.rawValue:
			//如果要该情景在界面中不存在，则刷新界面。
			if !scenePanels.elementsEqual(getScenePanelsFromDatabase()) {
				collectionView.reloadData()
			}
		default: break
		}
	}
	
	func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
		collectionView.reloadData()
		self.collectionView.header.endRefreshing()
	}
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
