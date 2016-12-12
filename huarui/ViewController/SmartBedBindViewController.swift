//
//  SmartBedBindViewController.swift
//  huarui
//
//  Created by sswukang on 15/6/4.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class SmartBedBindViewController: UITableViewController {

    var bedDev: HRSmartBed!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    private var tabBar: UIView?
    
    override func viewWillAppear(animated: Bool) {
        if let tabBar = tabBarController?.tabBar{
            self.tabBar = tabBar
            UIView.transitionWithView(tabBar, duration: 0.1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                tabBar.frame = CGRectMake(0, tabBar.frame.maxY + 200, tabBar.frame.width, tabBar.frame.height)
                }, completion: nil)
            
        }
        

    }
    
    override func viewWillDisappear(animated: Bool) {
        if let tabBar = self.tabBar{
            UIView.transitionWithView(tabBar, duration: 0.1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                tabBar.frame = CGRectMake(0, tabBar.frame.minY - 200 - tabBar.frame.height, tabBar.frame.width, tabBar.frame.height)
                }, completion: nil)
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        tableView.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
//        tableView.scrollEnabled = false
//        tableView.tableHeaderView = UIView(frame: CGRect.zeroRect)
        tableView.tableFooterView = UIView(frame: CGRect.zeroRect)
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 4
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 30.0
//    }
//
//    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//    }
//    
//    override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
//        
//    }
    

//    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        var v = UIView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
//        v.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
//        tableView.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
//        tableView.scrollEnabled = false
//        return v
//    }
    
//    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        var v = UIView(frame: CGRectMake(0, 0, view.frame.width, view.frame.height))
//        v.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
//        
//        return v
//    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier", forIndexPath: indexPath) as! UITableViewCell
        var text = ""
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        cell.backgroundColor = UIColor.whiteColor()
        
        if indexPath.row == 0{
            cell.frame = CGRectMake(cell.frame.minX, cell.frame.minY, cell.frame.width, 30)
            cell.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            var v = UIView(frame: cell.frame)
            v.backgroundColor = UIColor(red: 239/255.0, green: 238/255.0, blue: 244/255.0, alpha: 1)
            cell.accessoryType = UITableViewCellAccessoryType.None
            cell.selectedBackgroundView = v
        }
        if indexPath.row == 1{
            text = "床头推杆"
        }
        else if indexPath.row == 2{
            text = "床尾推杆"
        }
        else if indexPath.row == 3{
            text = "震动器"
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            text = ""
        }
        cell.textLabel?.text = text
        return cell
    }
    

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.selected = false
        if indexPath.row == 0 {
            return
        }
        performSegueWithIdentifier("showBindDetail", sender: indexPath.row + 1)
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showBindDetail" {
            let controller = segue.destinationViewController as! SmartBedBindDetailViewController
            let index = sender as! Int
            var title = ""
            switch index {
            case 1: title = "床头推杆"
            case 2: title = "床尾推杆"
            case 3: title = "震动器"
            default : break
            }
            controller.bindTitle = title
            controller.index = sender as! Int
            controller.bedDev = self.bedDev
        }
    }


}
