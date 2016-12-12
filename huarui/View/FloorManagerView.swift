//
//  ScrollTitleView.swift
//  TitleSlider
//
//  Created by sswukang on 15/3/3.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

/// 家居管理界面之房间管理的主view
class FloorManagerView: UIView, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate{
    var titleHeight: CGFloat = 36
    var titleWidth : CGFloat = 60
    var scrHeight  : CGFloat = 36
    var scrBgColor : UIColor =  .lightGrayColor()
    var dropBtnColor:UIColor = UIColor(white: 0.8, alpha: 0.6)
    var buttonImage: UIImage?
    var titleColorNormal     = UIColor.whiteColor()
    var titleColorSelected   = UIColor.redColor()
    var titleSizeNormal  :CGFloat   = 13
    var titleSizeSelected:CGFloat   = 20
    /**两个标题之间的间隔*/
	var titlesGap       :CGFloat   = 20
	var currentFloorId   : UInt16!
	var currentFloorName : String!
	var currentRoomId    : UInt16!
	var currentRoomName  : String!
	var currentRooms   :[UInt16: String]!
	var groups          :[UInt16: String]!
	weak var delegate : FloorManagerViewDelegate?
	
	private var titlesView: ScrollTitleView!
    private var titleScroll   : UIScrollView!
    private var contents : UIScrollView!
    private var dropTableView: UITableView!

//MARK: - 方法
    override init(frame: CGRect){
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.opaque = false
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        reloadData()
    }
    
    func reloadData() {
        if delegate == nil {
            Log.debug("ScrollTitleView: 没有设置代理，请设置ScrollTitleViewDelegate。")
            return
        } 
        groups = delegate!.floorManagerViewGetFloors()
        if groups.count == 0 {
            Log.warn("ScrollTitleView: 没有楼层数据，请设置delegate的scrollTitleViewGetGroups。")
            
            
            return
        }
        if currentFloorId == nil || groups[currentFloorId!] == nil{
            currentFloorId   = groups.first!.0
            currentFloorName = groups.first!.1
        }
		
		currentRooms = delegate!.floorManagerView(self, roomsForFloor: currentFloorId!, floorName: currentFloorName!)
        if currentRooms.count == 0 {
            Log.debug("ScrollTitleView: 没有房间数据，请设置delegate的scrollTitleViewGetGroups。")
            
           // print("ScrollTitleView: 没有房间数据，请设置delegate的scrollTitleViewGetGroups。")
            
            
            return
        }
        if currentRoomId == nil || currentRooms[currentRoomId!] == nil {
            currentRoomId   = currentRooms.first!.0
            currentRoomName = currentRooms.first!.1
        }
        
        self.addViews()
        self.addDropTableView()
		self.addTitlesView()
        self.addDropDownButton()
    }
	
	private func addTitlesView() {
		if titlesView == nil {
			titlesView = ScrollTitleView(frame: CGRectMake(0, 0, frame.width, scrHeight))
			titlesView.backgroundColor = scrBgColor
			titlesView.tintColor       = titleColorSelected
			titlesView.titleColor      = titleColorNormal
			titlesView.cursorHeight    = 3
			titlesView.containerScrollView.contentInset.right = scrHeight
		}
		insertSubview(titlesView, aboveSubview: dropTableView)
		titlesView.titles = Array(currentRooms.values)
		titlesView.setNeedsDisplay()
		titlesView.setHandler { [unowned self](index, title) -> Void in
			self.setPosition(index, setTitlePos: false)
		}
	}
	
	private var buttonTags: [Int]!
    
    private func addDropTableView(){
        if dropTableView != nil {
            dropTableView.removeFromSuperview()
        }
        dropTableView = UITableView()
        dropTableView.frame = CGRectMake(0, titleHeight, self.frame.width, 0)
        dropTableView.tableFooterView = UIView(frame: CGRect.zero)
        dropTableView.backgroundColor = scrBgColor
		dropTableView.contentInset.bottom = titleHeight + 5
        
        dropTableView.delegate = self
        dropTableView.dataSource = self
        
        //风格
        dropTableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        self.insertSubview(dropTableView, atIndex: 4)
    }
    
    private func addViews(){
        if contents != nil {
            contents.removeFromSuperview()
        }
        contents = UIScrollView(frame: CGRectMake(0, titleHeight, frame.width, frame.height - titleHeight))
        
        contents.showsHorizontalScrollIndicator = false
        contents.showsVerticalScrollIndicator   = false
        contents.bounces = false
        
        let view = UIView(frame: contents.frame)
        insertSubview(view, belowSubview: contents)
		let roomIds = currentRooms.keys
        for (index, id) in roomIds.enumerate() {
			let view = delegate!.floorManagerView(self, viewForRoom: id, roomName: currentRooms[id]!, floorId: currentFloorId!, floorName: currentFloorName!)
            view.frame = CGRectMake(frame.width * CGFloat(index), 0, frame.width, frame.height - titleHeight)
            contents.addSubview(view)
        }
        contents.pagingEnabled = true
        contents.delegate = self
        contents.contentSize = CGSizeMake(frame.width * CGFloat(currentRooms.count), frame.height - titleHeight)
		addSubview(contents)
		contents.contentOffset.x = titlesView != nil ? CGFloat(titlesView.currentPos) * frame.width:0
    }
	
	/// 获取房间View
	func getRoomViewWithTag(tag: Int) -> UIView? {
		return contents.viewWithTag(tag)
	}
    
    var dropButton: UIButton!
    private func addDropDownButton(){
        if dropButton != nil{
            dropButton.removeFromSuperview()
        }
        dropButton = UIButton(type: UIButtonType.Custom)
        dropButton.frame = CGRectMake(self.frame.width - titleHeight, 0, titleHeight, titleHeight)
        if buttonImage == nil {
            buttonImage = UIImage(named: "下拉按钮")
        }
        dropButton.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
        dropButton.backgroundColor = dropBtnColor
        //            UIColor(red: 154/255.0, green: 223/255.0, blue: 209/255.0, alpha: 0.6)
        dropButton.addTarget(self, action: #selector(FloorManagerView.tapDropDownButton(_:)), forControlEvents: UIControlEvents.TouchDown)
        addSubview(dropButton)
    }
    
    
    
    private var isDropListViewDown = false
    
    func tapDropDownButton(button: UIButton) {
        if !self.isDropListViewDown {
            self.bringSubviewToFront(dropTableView) //将dropTableView移到最顶层
            self.bringSubviewToFront(dropButton)    //再将dropButton移到最顶层
        }
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            if self.isDropListViewDown {    //恢复
                self.dropTableView.frame = CGRectMake(0, self.titleHeight, self.dropTableView.frame.width, 0)
                button.frame = CGRectMake(self.frame.width - self.titleHeight, 0, self.titleHeight, self.titleHeight)
            } else {  //下拉
                self.dropTableView.frame = CGRectMake(0, self.titleHeight, self.dropTableView.frame.width, self.frame.height - self.titleHeight)
                let layer = button.layer
                layer.frame = CGRectMake(0, self.frame.height-self.dropButton.frame.height, self.frame.width, self.dropButton.frame.height)
            }
            self.isDropListViewDown = !self.isDropListViewDown
            }, completion: onSelectedComplete)
    }
    
    func onSelectedComplete(comp: Bool) {
        if isTableSeledted {
            for v in subviews {
                v.removeFromSuperview()
            }
            reloadData()
            isTableSeledted = false
        }
        
    }
    
    //MARK: - TableView
	
	private var floorIds: [UInt16]?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		groups = delegate?.floorManagerViewGetFloors()
        if let g = groups {
			floorIds = Array(g.keys)
			return floorIds!.count
        }
		return 0
    }
	
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = groups![floorIds![indexPath.row]]
        cell.backgroundColor = scrBgColor
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        if currentFloorId == floorIds![indexPath.row] {
            cell.textLabel?.textColor = titleColorSelected
        } else {
            cell.textLabel?.textColor = titleColorNormal
        }
        return cell
    }
    
    private var isTableSeledted = false
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		currentFloorId   = floorIds![indexPath.row]
        currentFloorName = groups![currentFloorId!]
		currentRooms = delegate?.floorManagerView(self, roomsForFloor: currentFloorId!, floorName: currentFloorName!)
        if currentRooms.count < 1 {
            currentRoomName = "(无房间)"
		} else {
            currentRoomId   = currentRooms.first!.0
            currentRoomName = currentRooms.first!.1
        }
        isDropListViewDown = true
        isTableSeledted = true
        tapDropDownButton(dropButton)
    }
	
	func setPosition(pos: Int, setTitlePos: Bool = true) {
		if (pos < 0 || pos >= currentRooms.count) {
			Log.warn("ScrollTitleView.setPosition错误：设置的位置(\(pos))超出范围")
			return
		}
		let offset = CGFloat(pos) * self.frame.width
		contents.setContentOffset(CGPointMake(offset, 0), animated: false)
		if setTitlePos {
			titlesView.setSelectedItem(pos, animated: true)
		}
		let roomIDs = Array(self.currentRooms.keys)
		currentRoomId  = roomIDs[pos]
		currentRoomName = self.currentRooms[currentRoomId]
		
		delegate?.floorManagerView(self, didSelectedRoom: currentRoomId, roomName: currentRoomName, floorId: currentFloorId, floorName: currentFloorName)
	}
	
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        let page = Int(offset) / Int(self.frame.width)
        setPosition(page)
    }
	
    private func getLabelSize(string: String, fontSize: CGFloat) -> CGSize {
        let str = NSString(string: string)
        let attr = [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)]
        let size = str.sizeWithAttributes(attr)
        return size
    }
}

//MARK: - ScrollTitleViewDelegate

protocol FloorManagerViewDelegate: class {
	
	func floorManagerView(floorManagerView: FloorManagerView, viewForRoom roomId: UInt16, roomName: String, floorId: UInt16, floorName: String) -> UIView
    
    /**获取指定组里所有的房间名, key是房间ID，value是房间名*/
	func floorManagerView(floorManagerView: FloorManagerView, roomsForFloor floorId: UInt16, floorName: String) -> [UInt16: String]
    
    /**获取楼层名字典, key是楼层ID，value是楼层名*/
	func floorManagerViewGetFloors() -> [UInt16: String]
    
	//**选中某个房间
	func floorManagerView(floorManagerView: FloorManagerView, didSelectedRoom roomId: UInt16, roomName: String, floorId: UInt16,floorName: String)
}

