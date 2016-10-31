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
    var friends:[PFUser] = []

    
    @IBAction func onEdit(_ sender: AnyObject) {
        self.performSegue(withIdentifier: SEGUE_EDIT_FRIENDS, sender: sender)
    }
    
    func onLoad(){
        friendUtil = FriendUtil()
        friendUtil?.updateFriendships()
        friendUtil?.delegate = self
    }
    
    func dynamicallyCreateCell(_ index:Int) -> UITableViewCell{
        let thisUser:PFUser = self.friends[index] as! PFUser

        let reuseIdentifier = "Cell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style:.default, reuseIdentifier: reuseIdentifier)
        }
        
        cell?.textLabel?.text = thisUser.username
        cell?.backgroundColor = UIColor.clear
        //cell.accessoryType   = UITableViewCellAccessoryType.DetailDisclosureButton
        cell?.selectionStyle  = UITableViewCellSelectionStyle.default
        //cell.imageView.image = createThumbnail("")
        
        return cell!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        onLoad()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUMBER_OF_SECTIONS
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dynamicallyCreateCell((indexPath as NSIndexPath).row)
    }

    //MARK: - Pass friends:Array  to EditFriendsViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SEGUE_EDIT_FRIENDS {
            //Pass Array from one view to the next
            let vc = segue.destination as! EditFriendsTableViewController
                vc.friends = self.friends as! [PFUser]
        }
    }
}

//MARK: - Friends

extension FriendsTableViewController: FriendUtilDelegate{
    func relationshipDidComplete(_ users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        //myLog(users)
        self.friends = users as! [Any] as! [PFUser] //(users as! [PFUser])
        self.tableView.reloadData()
    }
    func relationshipDidFail(_ message: String) {
        //myLog(message)
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: message, sender: self)
    }
}
