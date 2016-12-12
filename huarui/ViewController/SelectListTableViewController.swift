//
//  SlectListTableViewController.swift
//  huarui
//
//  Created by sswukang on 15/8/29.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class SelectListTableViewController: UITableViewController {

	var textList: [String]!
	/// 不可选的列表，如果该列表有值则会在界面分组显示，状态为不可选；如果列表为nil则不显示
	var disableTextList: [String]?
	var selectedIndex: Int = -1
	/// 可选列表的标题
	var enableTitleInfo : String?
	/// 不可选列表的标题
	var disableTitleInfo: String?
	weak var delegate: SelectListTableViewControllerDelegate?
	
    override func viewDidLoad() {
		super.viewDidLoad()
		tableView.backgroundColor = UIColor.tableBackgroundColor()
		tableView.separatorColor = UIColor.tableSeparatorColor()
		tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
    }
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		if disableTextList == nil { return 1 }
		return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 { return textList == nil ? 0:textList!.count }
		return disableTextList == nil ? 0:disableTextList!.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) 
		if indexPath.section == 0 {
			cell.textLabel!.text = textList[indexPath.row]
			if indexPath.row == selectedIndex {
				cell.accessoryType = .Checkmark
			} else {
				cell.accessoryType = .None
			}
		} else {
			cell.textLabel?.text = disableTextList?[indexPath.row]
			cell.textLabel?.textColor = UIColor.lightGrayColor()
			cell.selectedBackgroundView = UIView()
		}
        return cell
    }
	
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50
	}
	
	override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if section == 0 && enableTitleInfo != nil && disableTitleInfo != nil && disableTextList!.count != 0  {
			let label = UILabel(frame: CGRectMake(0, 15, tableView.frame.width, 45))
			label.textAlignment = .Center
			label.font = UIFont.systemFontOfSize(label.font.pointSize-3)
			label.textColor = UIColor.lightGrayColor()
			label.text = enableTitleInfo!
			return label
		}
		if section == 1 && disableTitleInfo != nil && disableTextList!.count != 0 {
			let label = UILabel(frame: CGRectMake(0, 15, tableView.frame.width, 45))
			label.textAlignment = .Center
			label.font = UIFont.systemFontOfSize(label.font.pointSize-3)
			label.textColor = UIColor.lightGrayColor()
			label.text = disableTitleInfo!
			return label
		}
		return nil
	}
	
//MARK: - UI事件

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let currentCell = tableView.cellForRowAtIndexPath(indexPath)
		if indexPath.section == 1 {
			currentCell?.selected = false
			return
		}
		for i in 0..<tableView.numberOfRowsInSection(0) {
			let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))
			cell?.accessoryType = .None
		}
		currentCell?.accessoryType = .Checkmark
		delegate?.selectList(indexPath.row, textList: self.textList)
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}

protocol SelectListTableViewControllerDelegate: class {
	func selectList(didSelectRow: Int, textList: [String]!);
}
