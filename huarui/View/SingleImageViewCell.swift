//
//  SingleImageViewCell.swift
//  huarui
//
//  Created by sswukang on 16/3/1.
//  Copyright © 2016年 huarui. All rights reserved.
//

import UIKit

class SingleImageViewCell: UICollectionViewCell {
	
	var image: UIImage? {
		didSet {
			self.imageView.image = image
		}
	}
	
	@IBOutlet weak var imageView: UIImageView!
}
