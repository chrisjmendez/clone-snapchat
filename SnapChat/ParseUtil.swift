//
//  UserUtil.swift
//  SnapChat
//
//  Created by Chris on 1/28/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import UIKit
import Parse

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


//MARK: - Parse Registration

@objc protocol UserUtilDelegate {
    @objc optional func didSignUp()
    @objc optional func didSignIn()
    @objc optional func didSignOut()
    @objc optional func didForgot()
    @objc optional func didFail(_ message:String)
}

class UserUtil {
    var delegate:UserUtilDelegate?

    func signUp(_ username:String, password:String){
        let user = PFUser()
            user.username = username
            user.email    = username
            user.password = password
            user.signUpInBackground { (success, error) -> Void in
                if success == true {
                    self.delegate?.didSignUp!()
                } else {
                    self.delegate?.didFail!("Sign up error")
                }
        }
    }
    
    func signIn(_ username:String, password:String){
        PFUser.logInWithUsername(inBackground: username, password: password) { (parseUser, error) -> Void in
            if parseUser != nil {
                self.delegate?.didSignIn!()
            } else {
                //let error = error?._userInfo["error"] as! String
                self.delegate?.didFail!( "Sign in error" )
            }
        }
    }
    
    func signOut(){
        PFUser.logOut()
    }
    
    func logOut(){
        signOut()
    }
    
    func forgot(){
        
    }
        
    //Initialized in App Delegate
    func track(){
        Parse.setApplicationId(Config.parse.APPLICATION_ID, clientKey: Config.parse.CLIENT_ID)
        
        let object = ["appVersion":0.9]
        PFAnalytics.trackAppOpened(launchOptions: object)
    }
}

//MARK: - Parse Friendships

protocol FriendUtilDelegate {
    func relationshipDidComplete(_ users:NSArray)
    func relationshipDidFail(_ message:String)
}

class FriendUtil: QueryUtilDelegate {
    
    let KEY_FRIEND_RELATION = "friendsRelation"
    
    var delegate:FriendUtilDelegate?
    
    //Source: EditFriendsTableViewController
    func findFriendsForEdit(){
        //TODO: - This needs conditions so we ask only for friends
        let queryUtil = QueryUtil()
            queryUtil.queryUsers()
            queryUtil.delegate = self
    }
    
    //Source: FirnedsTableViewController
    func updateFriendships(){
        //A. Get the currentUser who is logged in
        let currentUser = PFUser.current()
        //B. Get the currentUser's list friends from Parse
        let relation = currentUser?.object( forKey: KEY_FRIEND_RELATION ) as? PFRelation
        //C. Create a new query of the currentUser's friends
        let query = relation?.query()
            query?.order(byAscending: "username")
            //D. Make the query
            query?.findObjectsInBackground(block: { (objects, error) -> Void in
               if error != nil {
                    //let e = (error?._userInfo["error"] as! String)
                    self.delegate?.relationshipDidFail( "Update Error" )
                } else {
                    //E. Update the tableView
                    self.delegate?.relationshipDidComplete(objects! as NSArray)
                }
            })
    }
    
    func queryDidComplete(_ users: NSArray) {
        self.delegate?.relationshipDidComplete(users)
    }
    func queryDidFail(_ message: String) {
        self.delegate?.relationshipDidFail(message)
    }
}

//MARK: - Parse Queries

protocol QueryUtilDelegate {
    func queryDidComplete(_ objects:NSArray)
    func queryDidFail(_ message:String)
}

class QueryUtil {
    var delegate:QueryUtilDelegate?
    
    func query(_ className:String, key:String, orderBy:String="username"){
        let query = PFQuery(className: className)
            query.whereKey(key, equalTo: (PFUser.current()?.objectId)!)
            query.order(byDescending: orderBy)
            query.findObjectsInBackground { (objects, error) -> Void in
                if error != nil{
                    self.delegate?.queryDidFail((error?.localizedDescription)!)
                } else {
                    self.delegate?.queryDidComplete(objects! as NSArray)
                }
            }
    }
    
    func queryUsers(){
        let query = PFUser.query()
            query?.order(byAscending: "username")
            query?.findObjectsInBackground(block: { (objects, error) -> Void in
                if error != nil {
                    //let e = (error?._userInfo["error"] as! String)
                    self.delegate?.queryDidFail("Oh oh, there seems to be an error. ")
                }
                else if objects?.count > 0 {
                    self.delegate?.queryDidComplete(objects! as NSArray)
                }
                else {
                    self.delegate?.queryDidFail("Friends not found.")
                }
            })
    }
}
