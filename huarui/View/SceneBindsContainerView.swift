//
//  SceneBindContainerView.swift
//  huarui
//
//  Created by sswukang on 16/2/26.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

/// 显示情景(或定时任务、传感器联动)里绑定的设备列表的view
class SceneBindsContainerView: UIView, UITableViewDelegate, UITableViewDataSource, TimePickerActionViewDelegate {

	var deviceTypes = [PickDeviceType]()
	var deviceDatas = [PickDeviceType: [HRDevInScene]]()
	var enable = true
	weak var delegate: SceneBindContainerViewDelegate?
	
	var tableView: UITableView!
	private var scrollTitleView: ScrollTitleView!
	private var effectView: UIView?
	private var didTapScrollTitleView = false
	
    private let scrollTitleHeight:CGFloat             = 50
    private let tableViewSectionHeaderHeight: CGFloat = 50
    private let tableViewRowHeight: CGFloat           = 50
	
	//MARK: - function
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initViews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initViews()
	}
	
	private func initViews() {
		scrollTitleView = ScrollTitleView()
		tableView = UITableView(frame: self.bounds, style: .Grouped)
		self.addSubview(tableView)
        tableView.dataSource          = self
        tableView.delegate            = self
        tableView.scrollsToTop        = true
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor     = UIColor.tableBackgroundColor()
        tableView.separatorColor      = UIColor.tableSeparatorColor()
        tableView.contentInset.top	  = scrollTitleHeight
		tableView.scrollIndicatorInsets.top  = scrollTitleHeight
	}
	
    override func drawRect(rect: CGRect) {
		if #available(iOS 8.0, *) {	//如果是iOS8或以上系统，则使用模糊效果
			let effectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
			self.addSubview(effectView)
			effectView.contentView.addSubview(scrollTitleView)
            effectView.frame                = CGRectMake(0, 0, rect.width, scrollTitleHeight)
            scrollTitleView.frame           = effectView.bounds
            scrollTitleView.backgroundColor = .clearColor()
            self.effectView                 = effectView
		} else {
			self.addSubview(scrollTitleView)
			scrollTitleView.frame = CGRectMake(0, 0, rect.width, scrollTitleHeight)
		}
        scrollTitleView.tintColor = self.tintColor
        scrollTitleView.titles    = deviceTypes.map{$0.description}
		scrollTitleView.setHandler { (pos, title) -> Void in
			var offset = CGPointMake(0, -self.scrollTitleHeight)
			for section in 0..<pos {
				let rows = self.tableView.numberOfRowsInSection(section)
				offset.y += self.tableViewRowHeight * CGFloat(rows)
				offset.y += self.tableViewSectionHeaderHeight
			}
			self.didTapScrollTitleView = true
			self.sectionFrameMaxYs.removeAll()
			self.tableView.setContentOffset(offset, animated: true)
		}
    }
	
	//MARK: - UITableView delegate
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return deviceTypes.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let type = deviceTypes[section]
		return deviceDatas[type]?.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell:SceneBindCell!  = tableView.dequeueReusableCellWithIdentifier("section\(indexPath.section)_cell") as? SceneBindCell
		let devInScene = getDevInScene(indexPath)!
		
		if cell == nil {
			cell = SceneBindCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "section\(indexPath.section)_cell", devInTask: devInScene)
		} else {
			cell.sceneBind = devInScene
		}
		cell.enabled = enable
		return cell
	} 
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return tableViewRowHeight
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return tableViewSectionHeaderHeight
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let type = deviceTypes[section]
		let count = deviceDatas[type]?.count ?? 0
		return count == 0 ? "":"\(type.description): \(count)"
	}
	
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return enable ? .Delete:.None
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		let type = deviceTypes[indexPath.section]
		deviceDatas[type]?.removeAtIndex(indexPath.row)
		let cell = tableView.cellForRowAtIndexPath(indexPath) as? SceneBindCell
		cell?.free()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)
		self.delegate?.bindsContainerView(self, didChangedDeviceDatas: deviceDatas)
	}
	
	//点击cell
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if !enable {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
			return
		}
        let dev   = getDevInScene(indexPath)!
        let title = dev.device!.name
        let delay = Float(dev.delayCode[0])/10
		TimePickerActionView(title: title, initSecond: delay, delegate: self).show()
	}
	
	//MARK: - other function 
	
	//延时选择器返回结果
	func timePickerActionView(picker: TimePickerActionView, dismissWithTimeInSecond second: Float) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		let devInScene = getDevInScene(indexPath)!
		if let relay = devInScene.device as? HRRelayInBox
			where Int(relay.relaySeq) < devInScene.delayCode.count {
				devInScene.delayCode = [
					relay.relaySeq == 0 ? Byte(second * 10) : 0,
					relay.relaySeq == 1 ? Byte(second * 10) : 0,
					relay.relaySeq == 2 ? Byte(second * 10) : 0,
					relay.relaySeq == 3 ? Byte(second * 10) : 0,
				]
		} else {
			devInScene.delayCode[0] = second <= 25.5 ? Byte(second * 10):0
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
	}
	
	func timePickerActionView(dismissWithoutTime picker: TimePickerActionView) {
		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	private func getDevInScene(indexPath: NSIndexPath) -> HRDevInScene? {
		let type = deviceTypes[indexPath.section]
		return deviceDatas[type]?[indexPath.row]
	}
	
	///每一个Section的frame的最大Y值
	private var sectionFrameMaxYs = [CGFloat]()
	
	func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		sectionFrameMaxYs = [CGFloat]()
		sectionFrameMaxYs.append(0)
		for section in 0..<tableView.numberOfSections {
			let rows = tableView.numberOfRowsInSection(section)
			sectionFrameMaxYs.append(sectionFrameMaxYs[section] + tableViewRowHeight * CGFloat(rows) + tableViewSectionHeaderHeight)
		}
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		
		//根据tableView的移动设置scrollTitles中游标的位置
		if sectionFrameMaxYs.count > 0 {
			for i in 1..<sectionFrameMaxYs.count {
				if tableView.contentOffset.y + scrollTitleHeight
					> sectionFrameMaxYs[i] {
						continue
				} else {
					if scrollTitleView.currentPos != i-1 {
						scrollTitleView.setSelectedItem(i-1, animated: true)
					}
					break
				}
			}
		}
	}
	
	func scrollTitleViewDidSelectedItem(index: Int, selectedTitle title: String) {
		var height: CGFloat = 0
		for section in 0..<index {
			let rows = tableView.numberOfRowsInSection(section)
			height += tableViewRowHeight * CGFloat(rows)
			height += tableViewSectionHeaderHeight
		}
		tableView.setContentOffset(CGPointMake(0, -scrollTitleView.bounds.height + height), animated: true)
	}
}

protocol SceneBindContainerViewDelegate: class {
	func bindsContainerView(containerView: SceneBindsContainerView, didChangedDeviceDatas deviceDatas: [PickDeviceType: [HRDevInScene]])
}