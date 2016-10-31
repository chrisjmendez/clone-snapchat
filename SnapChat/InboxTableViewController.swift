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
    
    var messages:[PFObject] = []
    var selectedMessage:PFObject?
    
    var queryUtil:QueryUtil?
    
    var player:AVPlayer?

    @IBAction func onLogout(_ sender: AnyObject) {
        //Synchronous LogOut
        UserUtil().logOut()
        //Go back to LogIn
        goToView( SEGUE_ON_LOGIN )
    }
    
    //MARK: - On Load
    
    func goToView(_ identifier:String){
        self.performSegue(withIdentifier: identifier, sender: self)
    }
    
    func onLoad(){
        //A. Check to see if the user is Logged In
        if let currentUser = PFUser.current() {
            //print("InboxTableViewController::onLoad", currentUser.username )
            //Initialize QueryUtil for messages
            queryUtil = QueryUtil()
            queryUtil?.delegate = self
        } else {
            print("User Not Logged into App")
            goToView(SEGUE_ON_LOGIN)
        }
    }
    
    func loadVideo(_ selectedMessage:PFObject){
        
        let videoURL = selectedMessage.object(forKey: Messages.file) as! PFFile
        let playerURL  = URL(string: videoURL.url!)
        
        player = AVPlayer(url: playerURL!)
        player!.rate = 1
        player!.play()
        
        //The AVPlayerLayer neeeds to be added to the video player's layer and resized
        let playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: self.view.layer.bounds.width, height: self.view.layer.bounds.height)
        
        self.view.layer.addSublayer(playerLayer)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //A. Show activity monitor
        ActivityUtil.sharedInstance.showLoader(self.view)
        //B. Query any messages sent from my friends
        queryUtil?.query(Messages.className, key: Messages.recipientIds, orderBy: "createdAt")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch(segue.identifier){
        case SEGUE_ON_LOGIN?:
            //Clear the word "Back" from new users signin in
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            //Hide the "Back" button
            navigationItem.hidesBackButton = true
            break
        case SEGUE_SHOW_IMAGE?:
            let vc = segue.destination as! ImageViewController
            //myLog(selectedMessage)
                vc.thisMessage = selectedMessage
            break
        default:
            break
        }
        //Hide the tab controller
        segue.destination.hidesBottomBarWhenPushed = true
    }

    //MARK: - TableView

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMessage = messages[(indexPath as NSIndexPath).row] as! PFObject
        let fileType = selectedMessage!.object(forKey: Messages.fileType) as! String

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
        
        var recipientIds = NSMutableArray(array: (selectedMessage?.object(forKey: Messages.recipientIds))! as AnyObject as! [AnyObject])
        
        if recipientIds.count == 1 {
            //Delete
            self.selectedMessage?.deleteInBackground()
            myLog(recipientIds.count)
        }
        //Remove recipient and save
        else {
            myLog(recipientIds.count)
            if let currentUser = PFUser.current() {
                recipientIds.remove(currentUser.objectId!)
                selectedMessage?.saveInBackground()
                myLog(recipientIds.count)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let message = messages[(indexPath as NSIndexPath).row] as! PFObject
        cell.textLabel?.text = (message.object(forKey: Messages.senderName) as! String)
        
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }
}

//MARK: Parse Query Delegate

extension InboxTableViewController: QueryUtilDelegate{
    func queryDidComplete(_ objects: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        if objects.count > 0 {
            messages = objects as! [Any] as! [PFObject]
            self.tableView.reloadData()
        }
    }
    func queryDidFail(_ message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: message, sender: self)
    }
    
}
