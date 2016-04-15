//
//  FriendsTableViewController.swift
//  SnapChat
//
//  Created by Chris on 1/28/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//
//  Within EditFriendsViewController we wrote a query
//  to get all the users from Parse
//  
//  Now we just want the users saved to our friends relation
//  Steps:
//   1) Get the friends relation
//   2) Get all the users listed in that friend relation

import Async
import MBProgressHUD
import UIKit
import Parse

class FriendsTableViewController: UITableViewController {
    
    let SEGUE_EDIT_FRIENDS  = "editFriendsSegue"
    let KEY_FRIEND_RELATION = "friendsRelation"

    let NUMBER_OF_SECTIONS  = 1
    
    var friendUtil:FriendUtil?
    var friends = []

    
    @IBAction func onEdit(sender: AnyObject) {
        self.performSegueWithIdentifier(SEGUE_EDIT_FRIENDS, sender: sender)
    }
    
    func onLoad(){
        friendUtil = FriendUtil()
        friendUtil?.updateFriendships()
        friendUtil?.delegate = self
    }
    
    func dynamicallyCreateCell(index:Int) -> UITableViewCell{
        let thisUser:PFUser = self.friends[index] as! PFUser

        let reuseIdentifier = "Cell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style:.Default, reuseIdentifier: reuseIdentifier)
        }
        
        cell.textLabel?.text = thisUser.username
        cell.backgroundColor = UIColor.clearColor()
        //cell.accessoryType   = UITableViewCellAccessoryType.DetailDisclosureButton
        cell.selectionStyle  = UITableViewCellSelectionStyle.Default
        //cell.imageView.image = createThumbnail("")
        
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        onLoad()
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NUMBER_OF_SECTIONS
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return dynamicallyCreateCell(indexPath.row)
    }

    //MARK: - Pass friends:Array  to EditFriendsViewController
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEGUE_EDIT_FRIENDS {
            //Pass Array from one view to the next
            let vc = segue.destinationViewController as! EditFriendsTableViewController
                vc.friends = self.friends as! [PFUser]
        }
    }
}

//MARK: - Friends

extension FriendsTableViewController: FriendUtilDelegate{
    func relationshipDidComplete(users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        //myLog(users)
        self.friends = users //(users as! [PFUser])
        self.tableView.reloadData()
    }
    func relationshipDidFail(message: String) {
        //myLog(message)
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: message, sender: self)
    }
}
