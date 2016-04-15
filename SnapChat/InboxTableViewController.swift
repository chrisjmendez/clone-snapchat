//
//  InboxTableViewController.swift
//  SnapChat
//
//  Created by Chris on 1/27/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import Async
import AVFoundation
import Parse
import UIKit

class InboxTableViewController: UITableViewController {
    
    let SEGUE_SHOW_IMAGE = "showImageSegue"
    let SEGUE_SHOW_VIDEO = "showVideoSegue"
    let SEGUE_ON_LOGIN  = "onLoginSegue"
    
    var messages = []
    var selectedMessage:PFObject?
    
    var queryUtil:QueryUtil?
    
    var player:AVPlayer?

    @IBAction func onLogout(sender: AnyObject) {
        //Synchronous LogOut
        UserUtil().logOut()
        //Go back to LogIn
        goToView( SEGUE_ON_LOGIN )
    }
    
    //MARK: - On Load
    
    func goToView(identifier:String){
        self.performSegueWithIdentifier(identifier, sender: self)
    }
    
    func onLoad(){
        //A. Check to see if the user is Logged In
        if let currentUser = PFUser.currentUser() {
            //print("InboxTableViewController::onLoad", currentUser.username )
            //Initialize QueryUtil for messages
            queryUtil = QueryUtil()
            queryUtil?.delegate = self
        } else {
            print("User Not Logged into App")
            goToView(SEGUE_ON_LOGIN)
        }
    }
    
    func loadVideo(selectedMessage:PFObject){
        
        let videoURL = selectedMessage.objectForKey(Messages.file) as! PFFile
        let playerURL  = NSURL(string: videoURL.url!)
        
        player = AVPlayer(URL: playerURL!)
        player!.rate = 1
        player!.play()
        
        //The AVPlayerLayer neeeds to be added to the video player's layer and resized
        let playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: self.view.layer.bounds.width, height: self.view.layer.bounds.height)
        
        self.view.layer.addSublayer(playerLayer)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        //A. Show activity monitor
        ActivityUtil.sharedInstance.showLoader(self.view)
        //B. Query any messages sent from my friends
        queryUtil?.query(Messages.className, key: Messages.recipientIds, orderBy: "createdAt")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch(segue.identifier){
        case SEGUE_ON_LOGIN?:
            //Clear the word "Back" from new users signin in
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            //Hide the "Back" button
            navigationItem.hidesBackButton = true
            break
        case SEGUE_SHOW_IMAGE?:
            let vc = segue.destinationViewController as! ImageViewController
            //myLog(selectedMessage)
                vc.thisMessage = selectedMessage
            break
        default:
            break
        }
        //Hide the tab controller
        segue.destinationViewController.hidesBottomBarWhenPushed = true
    }

    //MARK: - TableView

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedMessage = messages[indexPath.row] as! PFObject
        let fileType = selectedMessage!.objectForKey(Messages.fileType) as! String

        switch fileType {
            case "video":
                loadVideo(selectedMessage!)
                break
            case "image":
                goToView(SEGUE_SHOW_IMAGE)
                break
        default:
            break
        }
        
        var recipientIds = NSMutableArray(array: (selectedMessage?.objectForKey(Messages.recipientIds))! as AnyObject as! [AnyObject])
        
        if recipientIds.count == 1 {
            //Delete
            self.selectedMessage?.deleteInBackground()
            myLog(recipientIds.count)
        }
        //Remove recipient and save
        else {
            myLog(recipientIds.count)
            if let currentUser = PFUser.currentUser() {
                recipientIds.removeObject(currentUser.objectId!)
                selectedMessage?.saveInBackground()
                myLog(recipientIds.count)
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let message = messages[indexPath.row] as! PFObject
        cell.textLabel?.text = (message.objectForKey(Messages.senderName) as! String)
        
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }
}

//MARK: Parse Query Delegate

extension InboxTableViewController: QueryUtilDelegate{
    func queryDidComplete(objects: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        if objects.count > 0 {
            messages = objects
            self.tableView.reloadData()
        }
    }
    func queryDidFail(message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: message, sender: self)
    }
    
}
