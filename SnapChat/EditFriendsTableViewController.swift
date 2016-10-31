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
        currentUser = PFUser.current()

        queryUsers()
    }
    
    //Dynamically create and Style a Prototype Cell
    //This simplifies having to tweak the UIStoryboard
    func dynamicallyCreateCell(_ index:Int) -> UITableViewCell{
        //A. Populate the cell with the specific Parse user
        let thisUser:PFUser = self.allUsers[index]
        //B. Create the cell
        let reuseIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style:.default, reuseIdentifier: reuseIdentifier)
        }
        //C. Decide whether the user is a friend or not and add a Checkmark
        if self.isFriend(thisUser) {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        //D. Stylize the cell
        cell?.textLabel?.text = thisUser.username
        cell?.backgroundColor = UIColor.clear
        cell?.selectionStyle  = UITableViewCellSelectionStyle.default
        //cell.imageView.image = createThumbnail("")
        return cell!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }

    //Add or delete selected friends
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print("You selected cell #\(indexPath.row)!")
        
        //You have to manually turn off the highligh when you tap out
        self.tableView.deselectRow(at: indexPath, animated: false)
        
        //Mark the selected cell with a checkbox
        let cell = tableView.cellForRow(at: indexPath)
        
        //A. Change Friendship
        let selectedUser:PFUser = self.allUsers[(indexPath as NSIndexPath).row]
        //B. Dump friend
        if self.isFriend(selectedUser) {
            print("REMOVE FRIEND")
            //1. Remove checkmark
            cell?.accessoryType = .none
            //2. Remove friend from local friends array
            friends = friends.filter({ $0.objectId != selectedUser.objectId })
            //3. Update backend database
            changeFriendship(selectedUser, didAdd: false)
        }
        //C. Make friend
        else {
            print("SAVE FRIEND")
            //1. Add checkmark
            cell?.accessoryType = .checkmark
            //2. Add friend to local friends array
            friends.append(selectedUser)
            //3. Update backend database
            changeFriendship(selectedUser, didAdd: true)
        }
    }

    //Display the users
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //Data will start reloading
        return dynamicallyCreateCell((indexPath as NSIndexPath).row)
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
    func isFriend(_ user:PFUser) -> Bool {
        //Compare Parse-made object ID's
        let match = friends.filter({ $0.objectId == user.objectId })
        //If user is a friend
        if match.count > 0 {
            return true
        }
        //If user is not a friend
        return false
    }
    
    func changeFriendship(_ user:PFUser, didAdd:Bool){
        //Create a Relationships between the currentUser and the user who's username was tapped
        let friendsRelation:PFRelation = ( currentUser?.relation(forKey: KEY_FRIEND_RELATION) as PFRelation! )
        
        //Add a friend
        if didAdd == true {
            friendsRelation.add(user)
        } else {
            //Remove a relationship
            friendsRelation.remove(user)
        }
        
        //Save any local changes made to the current user
        currentUser?.saveInBackground(block: { (success, error) -> Void in
            if error != nil {
                //let e = (error?._userInfo["error"] as! [String:Any])!
                AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: "Save Error", sender: self)
            } else if success == true {
                //AlertUtil().show(AlertUtilType.SUCCESS, title: "Friend Saved", message: "Your relationship has been saved", sender: self)
                self.myLog(user)
            }
        })
    }
    
    func relationshipDidFail(_ message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: message, sender: self)
    }
    
    func relationshipDidComplete(_ users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        //Force Cast NSArray to become PFUser
        self.allUsers = (users as! [PFUser])
        self.tableView.reloadData()
    }
}
