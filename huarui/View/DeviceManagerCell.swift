//
//  DeviceManagerCell.swift
//  huarui
//
//  Created by sswukang on 15/12/2.
//  Copyright © 2015年 huarui. All rights reserved.
//

import UIKit

/// 设备管理界面的cell
class DeviceManagerCell: UITableViewCell {

	@IBOutlet weak var devImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
