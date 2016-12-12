//
//  PickDeviceViewCell.swift
//  huarui
//
//  Created by sswukang on 16/3/7.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

///弹出选择设备时显示的列表的cell
class PickDeviceViewCell: UITableViewCell {
	private let  cellWidth = UIScreen.mainScreen().bounds.width
	
	var model: PickDeviceModel?
	
	private var descLabel: UILabel!
	private var colorField: UIView!

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		initViews()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initViews()
	}
	
	private func initViews() {
		descLabel = UILabel(frame: CGRectMake(cellWidth * 0.6, 0, cellWidth*0.4, contentView.bounds.height))
		descLabel.textColor = UIColor.lightGrayColor()
		descLabel.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		contentView.addSubview(descLabel)
		
		colorField = UIView(frame: CGRectMake(cellWidth * 0.6, 0, contentView.bounds.height * 0.8, contentView.bounds.height * 0.8))
		colorField.layer.cornerRadius = colorField.bounds.width/2
		colorField.layer.borderColor = UIColor(R: 0xDD, G: 0xDD, B: 0xDD, alpha: 1).CGColor
		colorField.center.y = contentView.bounds.midY
		contentView.addSubview(colorField)
		
		detailTextLabel?.textColor = .lightGrayColor()
	}
	
	func setModel(model: PickDeviceModel) {
		self.model = model
		imageView?.image = UIImage(named: model.device.iconName)?.imageWithRenderingMode(.AlwaysTemplate)
		accessoryType    = model.selected ? .Checkmark:.None
		textLabel?.text = model.device.name
		switch model.type {
		case .Relay, .Motor:
			detailTextLabel?.hidden = false
			detailTextLabel?.text = "\(model.device.insFloorName ?? "未知楼层") - \(model.device.insRoomName ?? "未知房间")"
		case .Apply:
			detailTextLabel?.hidden = false
			detailTextLabel?.text = "\(model.device.insFloorName ?? "未知楼层") - \(model.device.insRoomName ?? "未知房间")"
			descLabel.hidden = !model.selected
			descLabel.text = model.infraredDecription
		case .RGB:
			detailTextLabel?.text = "\(model.device.insFloorName ?? "未知楼层") - \(model.device.insRoomName ?? "未知房间")"
			if model.selected {
				if let description = model.rgbDescription {
                    descLabel.hidden  = false
                    colorField.hidden = true
                    descLabel.text    = description
				} else {
					let R = Int(model.actBinds[1])
					let G = Int(model.actBinds[2])
					let B = Int(model.actBinds[3])
					colorField.layer.backgroundColor = UIColor(R: R, G: G, B: B, alpha: 1).CGColor
					if R + G + B > 255*3-30 {
						colorField.layer.borderWidth = 0.5
					} else {
						colorField.layer.borderWidth = 0
					}
                    colorField.hidden = false
                    descLabel.hidden  = true
				}
			} else {
				descLabel.hidden = true
				colorField.hidden = true
			}
		case .Scene:
			detailTextLabel?.hidden = true
		}
	}
}
