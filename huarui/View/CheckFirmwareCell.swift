//
//  CheckFirmwareCell.swift
//  huarui
//
//  Created by 海波 on 16/3/25.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

class CheckFirmwareCell: UITableViewCell {
    
    ///cell的高度
    var cellHeight : CGFloat = 0.0
    
    
    @IBOutlet weak var versionLabel: UILabel!
        
    @IBOutlet weak var descriptionLabel: UILabel!
        
    @IBOutlet weak var sizeLabel: UILabel!
        
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.cellHeight += 80.0
        
        if let text = self.dateLabel?.text {
            let textSize = NSString(string: text).sizeWithAttributes([NSFontAttributeName : self.dateLabel.font])
            self.cellHeight += textSize.height
        }
    }
    

   

    
    
}
