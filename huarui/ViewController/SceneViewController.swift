//
//  SceneViewController.swift
//  huarui
//
//  Created by sswukang on 15/1/21.
//  Copyright (c) 2015年 huarui. All rights reserved.
//


import UIKit

class SceneViewController: BaseManagerViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, HRSceneUpdateDelegate, HR8000HelperDelegate, UIAlertViewDelegate {
	
	
    var scenes: [HRScene]!
    //没有情景的时候提示“无情景”的view
    private var noDevicesTipsView: UIView?
    
//    private var addBarButton: UIBarButtonItem!
    
	private var collectionView: UICollectionView!
	private var _currentSlectedDevice: HRDevice?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
	
//MARK: - ViewController
	
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
        collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, tabHeight, 1)
        collectionView.dataSource = self
        collectionView.delegate   = self
		
		//下拉刷新组件
		let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(SceneViewController.collectionViewWillRefresh))
		header.tintColor = UIColor.whiteColor()
		header.setTitle("下拉刷新", forState: MJRefreshStateIdle)
		header.setTitle("松开刷新数据", forState: MJRefreshStatePulling)
		header.setTitle("WillRefresh", forState: MJRefreshStateWillRefresh)
		header.setTitle("正在刷新数据...", forState: MJRefreshStateRefreshing)
		header.lastUpdatedTimeLabel?.hidden = true
		
		collectionView.header = header
    }
    
	override func viewWillAppear(animated: Bool) {
		self.title = "情景模式"
		super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        HRProcessCenter.shareInstance().delegates.hr8000HelperDelegate = self
        HRProcessCenter.shareInstance().delegates.sceneUpdateDelegate  = self
        collectionView.reloadData()
    }
	
    override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
        HRProcessCenter.shareInstance().delegates.sceneUpdateDelegate = nil
    }

	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showCreateSceneViewController" {
			if let vc = (segue.destinationViewController as! UINavigationController).topViewController as? CreateSceneViewController {
				vc.sceneDevice = sender as? HRScene
			}
		}
	}
//MARK: - UI事件
	
	///下拉刷新
	func collectionViewWillRefresh() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SceneViewController.onQueryDeviceDone(_:)), name: kNotificationQueryDone, object: nil)
		
		HR8000Service.shareInstance().queryDevice(HRDeviceType.Scene)
		///3秒之后停止refreshing
		runOnMainQueueDelay(3000, block: {
			self.collectionView.header.endRefreshing()
		})
	}
	
	func onQueryDeviceDone(notification: NSNotification ){
		NSNotificationCenter.defaultCenter().removeObserver(self, name: kNotificationQueryDone, object: nil)
		self.collectionView.header.endRefreshing()
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
	
	private func getScenesFromDatabase() -> [HRScene] {
		if let scenes = HRDatabase.shareInstance().getDevicesOfType(.Scene) as? [HRScene] {
			return scenes
		}
		return [HRScene]()
	}
	
	//MARK: - UICollectionView dataSource & delegate
	
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        scenes = getScenesFromDatabase()
        if scenes.count == 0 {
			if self.noDevicesTipsView == nil {
				self.noDevicesTipsView = getTipView("无情景")
				self.noDevicesTipsView?.center = self.view.center
                self.view.addSubview(noDevicesTipsView!)
            }
        } else {
            self.noDevicesTipsView?.removeFromSuperview()
            self.noDevicesTipsView = nil
        }
        return scenes.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("deviceCell", forIndexPath: indexPath) as! DeviceCollectionViewCell
        cell.device = scenes?[indexPath.row]
		cell.shouldImageHighted = true
		
		if let gestures = cell.gestureRecognizers {
			for gesture in gestures {
				cell.removeGestureRecognizer(gesture)
			}
		}
        //增加长按手势
        let longGestrue = UILongPressGestureRecognizer(target: self, action: #selector(SceneViewController.onCellLongClicked(_:)))
        cell.addGestureRecognizer(longGestrue)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! DeviceCollectionViewCell
        
        if let scene = cell.device as? HRScene {
            
            KVNProgress.showWithStatus("正在启动 \(scene.name)")
            
            //启动情景
            scene.start({ (error) in
                if let err = error {
                    KVNProgress.showErrorWithStatus("启动失败: \(err.domain)(\(err.code))")
                } else {
                    KVNProgress.showSuccessWithStatus("启动成功")
                }
            })
        }
        
	}
	
	func onAddBarButtonClicked(barButton: UIBarButtonItem) {
		let controller = CreateSceneViewController()
		navigationController?.pushViewController(controller, animated: true)
	}
	
	
    func onCellLongClicked(gesture: UILongPressGestureRecognizer){
        switch gesture.state {
        case .Began:
            if let cell = gesture.view as? DeviceCollectionViewCell {
				if self.tabBarController?.tabBar == nil || currentDeviceModel == .iPad {
					cell.longClickedHandler(showInView: self.view, navigationController: self.navigationController)
				} else {
					cell.longClickedHandler(showInView: self.tabBarController!.tabBar, navigationController: self.navigationController)
				}
            }
        default: break
        }
    }
	

	
//MARK: - HR8000HelperDelegate
    
    func hr8000Helper(queryDeviceInfo device: HRDevice, indexOfDatabase index: Int, devices: [HRDevice]) {
        switch device.devType {
        case HRDeviceType.Scene.rawValue:
            //如果要该情景在界面中不存在，则刷新界面。
            if !self.scenes.elementsEqual(getScenesFromDatabase()) {
                collectionView.reloadData()
            }
        default: break
        }
    }

    func hr8000Helper(finishedQueryDeviceInfo finish: Bool) {
        collectionView.reloadData()
		self.collectionView.header.endRefreshing()
    }
    
//MARK: - HRSceneUpdateDelegate
    
    ///创建新的情景
    func sceneUpdate(sceneByCreate scene: HRScene, newScenes: [HRScene]) {
        self.scenes = newScenes
        let cellCount = collectionView.numberOfItemsInSection(0)
        let indexPath = NSIndexPath(forRow: cellCount, inSection: 0)
        var indexPaths = [NSIndexPath]()
        indexPaths.append(indexPath)
        collectionView.insertItemsAtIndexPaths(indexPaths)
    }
    
    ///更新情景信息
    func sceneUpdate(sceneByModify scene: HRScene, indexOfDatabase index: Int, newScenes: [HRScene]) {
        if scene.id != scenes[index].id {
            //如果同一个情景在不同的位置，那么直接reloadData
            self.scenes = newScenes
            collectionView.reloadData()
            return
        } else {
            self.scenes = newScenes
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! DeviceCollectionViewCell
            cell.setDeviceWithAnimation(scene, animated: true)
        }
    }
    
    ///删除情景
    func sceneUpdate(sceneByDelete scene: HRScene, indexOfDatabase index: Int, newScenes: [HRScene]) {
        if scene.id != scenes[index].id {
            //如果同一个情景在不同的位置，那么直接reloadData
            self.scenes = newScenes
            collectionView.reloadData()
            return
        } else {
            self.scenes = newScenes
            collectionView.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
        }
    }
	
}

