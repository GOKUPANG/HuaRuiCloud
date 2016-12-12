//
//  SmartBindDetailViewController.swift
//  huarui
//
//  Created by sswukang on 15/6/4.
//  Copyright (c) 2015年 huarui. All rights reserved.
//

import UIKit

class SmartBedBindDetailViewController: UITableViewController {
    var index: Int!
    var bedDev: HRSmartBed!
    var motors: [HRMotorCtrlDev]!
    var bindTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        navigationItem.title = bindTitle
    }
    
    private var tabBar: UIView?
    
    override func viewWillAppear(animated: Bool) {
        if let tabBar = tabBarController?.tabBar{
            self.tabBar = tabBar
            UIView.transitionWithView(tabBar, duration: 0.1, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                tabBar.frame = CGRectMake(0, tabBar.frame.maxY + 200, tabBar.frame.width, tabBar.frame.height)
                }, completion: nil)
            
        }
        
        motors = HR8000Helper.shareInstance()!.getMotors()
        
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
        tableView.tableFooterView = UIView(frame: CGRect.zeroRect)
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return motors.count+1
    }
       
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier", forIndexPath: indexPath) as! UITableViewCell
        
        var bindAddr: UInt32? = nil
        if index == 0{
            bindAddr = bedDev.poleHeadAddr
        }
        else if index == 1{
            bindAddr = bedDev.poleFootAddr
        }
        else if index == 2{
            bindAddr = bedDev.vibratoeAddr
        }
        
        var text = "无"
        if indexPath.row == 0{
            cell.textLabel?.text = "无"
            if bindAddr == nil {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        } else {
            cell.textLabel?.text = motors[indexPath.row-1].name
            if bindAddr != nil && bindAddr == motors[indexPath.row-1].devAddr{
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        }
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var row = indexPath.row
        if index == 0 {
            if row == 0{
                bedDev.poleHeadAddr = nil
            } else {
                bedDev.poleHeadAddr = motors[row-1].devAddr
            }
        }
        else if index == 1{
            if row == 0{
                bedDev.poleFootAddr = nil
            } else {
                bedDev.poleFootAddr = motors[row-1].devAddr
            }
        }
        else if index == 2{
            if row == 0{
                bedDev.vibratoeAddr = nil
            } else {
                bedDev.vibratoeAddr = motors[row-1].devAddr
            }
        }
        bedDev.saveToLoacal()
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
