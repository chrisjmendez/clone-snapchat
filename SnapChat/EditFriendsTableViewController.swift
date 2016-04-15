//
//  EditFriendsTableViewController.swift
//  SnapChat
//
//  Created by Chris on 1/27/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import Async
import MBProgressHUD
import UIKit
import Parse

class EditFriendsTableViewController: UITableViewController {

    //Parse Keys and Classes
    let KEY_FRIEND_RELATION = "friendsRelation"
    
    //List of Users from database
    var allUsers = [PFUser]()
    var friends  = [PFUser]()
    
    var friendUtil:FriendUtil?

    var currentUser:PFUser?
    
    func onLoad(){
        //Start off by getting the current user
        currentUser = PFUser.currentUser()

        queryUsers()
    }
    
    //Dynamically create and Style a Prototype Cell
    //This simplifies having to tweak the UIStoryboard
    func dynamicallyCreateCell(index:Int) -> UITableViewCell{
        //A. Populate the cell with the specific Parse user
        let thisUser:PFUser = self.allUsers[index]
        //B. Create the cell
        let reuseIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style:.Default, reuseIdentifier: reuseIdentifier)
        }
        //C. Decide whether the user is a friend or not and add a Checkmark
        if self.isFriend(thisUser) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        //D. Stylize the cell
        cell.textLabel?.text = thisUser.username
        cell.backgroundColor = UIColor.clearColor()
        cell.selectionStyle  = UITableViewCellSelectionStyle.Default
        //cell.imageView.image = createThumbnail("")
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onLoad()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }

    //Add or delete selected friends
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //print("You selected cell #\(indexPath.row)!")
        
        //You have to manually turn off the highligh when you tap out
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        //Mark the selected cell with a checkbox
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        //A. Change Friendship
        let selectedUser:PFUser = self.allUsers[indexPath.row]
        //B. Dump friend
        if self.isFriend(selectedUser) {
            print("REMOVE FRIEND")
            //1. Remove checkmark
            cell?.accessoryType = .None
            //2. Remove friend from local friends array
            friends = friends.filter({ $0.objectId != selectedUser.objectId })
            //3. Update backend database
            changeFriendship(selectedUser, didAdd: false)
        }
        //C. Make friend
        else {
            print("SAVE FRIEND")
            //1. Add checkmark
            cell?.accessoryType = .Checkmark
            //2. Add friend to local friends array
            friends.append(selectedUser)
            //3. Update backend database
            changeFriendship(selectedUser, didAdd: true)
        }
    }

    //Display the users
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        //Data will start reloading
        return dynamicallyCreateCell(indexPath.row)
    }
}

//MARK: - Parse Friendships

extension EditFriendsTableViewController: FriendUtilDelegate {
    func queryUsers(){
        ActivityUtil.sharedInstance .showLoader(self.view)
        
        friendUtil = FriendUtil()
        friendUtil?.findFriendsForEdit()
        friendUtil?.delegate = self
    }

    //Friends was instantiated from FriendsTableViewController
    func isFriend(user:PFUser) -> Bool {
        //Compare Parse-made object ID's
        let match = friends.filter({ $0.objectId == user.objectId })
        //If user is a friend
        if match.count > 0 {
            return true
        }
        //If user is not a friend
        return false
    }
    
    func changeFriendship(user:PFUser, didAdd:Bool){
        //Create a Relationships between the currentUser and the user who's username was tapped
        let friendsRelation:PFRelation = ( currentUser?.relationForKey(KEY_FRIEND_RELATION) as PFRelation! )
        
        //Add a friend
        if didAdd == true {
            friendsRelation.addObject(user)
        } else {
            //Remove a relationship
            friendsRelation.removeObject(user)
        }
        
        //Save any local changes made to the current user
        currentUser?.saveInBackgroundWithBlock({ (success, error) -> Void in
            if error != nil {
                AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: (error?.userInfo["error"] as! String), sender: self)
            } else if success == true {
                //AlertUtil().show(AlertUtilType.SUCCESS, title: "Friend Saved", message: "Your relationship has been saved", sender: self)
                self.myLog(user)
            }
        })
    }
    
    func relationshipDidFail(message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: message, sender: self)
    }
    
    func relationshipDidComplete(users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        //Force Cast NSArray to become PFUser
        self.allUsers = (users as! [PFUser])
        self.tableView.reloadData()
    }
}
