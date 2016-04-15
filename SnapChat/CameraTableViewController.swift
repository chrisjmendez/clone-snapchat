//
//  CameraTableViewController.swift
//  SnapChat
//
//  Created by Chris Mendez on 3/7/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import UIKit
import Async
import Cent
import MobileCoreServices
import Parse

class CameraTableViewController: UITableViewController {
    
    let MAX_VIDEO_DURATION:NSTimeInterval = 10
    
    //View controllers can be properties of other view controllers
    var image:UIImage?
    var imagePicker:UIImagePickerController?
    
    var videoFilePath:String?

    var friendUtil:FriendUtil?
    //List of current friends
    var friends    = []
    //Friends who will get this message
    var recipients = [String]()
    
    //MARK: - IBActions
    
    @IBAction func onCancel(sender: AnyObject) {
        //Cancel the entire send process
        clearLocalData()
        goToView(Config.appTab.INBOX)
    }
    
    @IBAction func onSend(sender: AnyObject) {
        //Ensure that a photo or video was captured or selected

        let vidIsEmpty = (videoFilePath ?? "").isEmpty
        if vidIsEmpty == true && image == nil {
            AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: "Please first pick a photo or video to send", sender: self)
        } else {
            uploadMessage()
        }
    }
    
    //MARK: - App Logic
    
    func clearLocalData(){
        image         = nil
        videoFilePath = ""
        recipients.removeAll()
    }
    
    func goToView(index:Int){
        //Take the user back to the inbox tab programatically
        self.tabBarController?.selectedIndex = index
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipients.removeAll()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initCamera()
        getFriends()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let thisUser:PFUser = self.friends[indexPath.row] as! PFUser
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as UITableViewCell!
            cell.textLabel?.text = thisUser.username
        
        //If the user has been selected, they should be in recipients.  If they are, they deserve a checkmark
        if recipients.contains(thisUser.objectId!){
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    //Tap on a friend and select a checkmark
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //We dont want the row to remain highlighted
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell

        //Selected User
        let user = self.friends[indexPath.row] as! PFUser
        
        if cell.accessoryType == .None {
            cell.accessoryType = .Checkmark
            //Just record the Parse user Object
            recipients.append( user.objectId! )
        } else {
            cell.accessoryType = .None
            //Just delete the Parse user object string from the array
            recipients = recipients.filter({ $0 != user.objectId! })
        }
    }
}


//MARK: - Image Manipulation

extension CameraTableViewController{
    private func resizeImage(sourceImage:UIImage, w:Int, h:Int) -> UIImage{
        let newSize = CGSize(width: w, height: h)
        let newRect = CGRect(x: 0, y: 0, width: w, height: h)
        //Create a context in which you manipulate a smaller verions of the image
        UIGraphicsBeginImageContext(newSize)
        sourceImage.drawInRect(newRect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        return resizedImage
    }
}

//MARK: - Friend Connection

extension CameraTableViewController: FriendUtilDelegate{

    func uploadMessage(){
        
        struct File {
            var data:NSData?
            let name:String?
            let type:String?
        }
        var file:File?

        //http://nshipster.com/nsoperation/
        Async.userInitiated {
            ActivityUtil.sharedInstance.showProgressLoader(self.view)
            
            //We're sending an image
            if self.image != nil {
                let newImage = self.resizeImage(self.image!, w: 256, h: 256)
                let png = UIImagePNGRepresentation(newImage)
                file = File(data: png, name: "image.png", type: "image")
            }
            //WE're sending a video
            else {
                let video = NSData.dataWithContentsOfMappedFile(self.videoFilePath!) as! NSData
                file = File(data: video, name: "video.mov", type: "video")
            }
            let parseFile = PFFile.init(name: file?.name, data: (file?.data)!)
            parseFile?.saveInBackgroundWithBlock({ (success, error) -> Void in
                if error != nil {
                    self.myLog("error")
                } else {
                    //This is where we construct a Parse Object using the Messages structure
                    let message = PFObject(className: Messages.className )
                        message.setObject(parseFile!, forKey: Messages.file)
                        //We need this when we are viewing messages in the inbox
                        message.setObject((file?.type)!, forKey: Messages.fileType)
                        message.setObject(self.recipients, forKey: Messages.recipientIds)
                        message.setObject((PFUser.currentUser()?.objectId)!, forKey: Messages.senderId)
                        message.setObject((PFUser.currentUser()?.username)!, forKey: Messages.senderName)
                        message.saveInBackgroundWithBlock({ (success, error) -> Void in
                            if error != nil {
                                self.myLog(error)
                            } else {
                                self.clearLocalData()
                                self.myLog("YES")
                            }
                            self.goToView(Config.appTab.INBOX)
                        })
                }
            },
            progressBlock: { (percentage) -> Void in
                let progress = Float( Double(percentage) * 0.01 )
                ActivityUtil.sharedInstance.updateLoader(progress)
                if progress >= 1.0 {
                    ActivityUtil.sharedInstance.hideLoader(self.view)
                }
            })
        }
    }
    
    func getFriends(){
        friendUtil = FriendUtil()
        friendUtil!.updateFriendships()
        friendUtil!.delegate = self
    }
    
    func relationshipDidComplete(users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        self.friends = users
        self.tableView.reloadData()
    }
    func relationshipDidFail(message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Error", message: message, sender: self)
    }
}

//MARK: - Camera related tasks

extension CameraTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func initCamera(){
        //A. Determine if a video or image has been picked by calculating whether they're empty
        let vidIsEmpty = (videoFilePath ?? "").isEmpty
        //B. If there's already a picked item or video, don't show the camera
        if image == nil && vidIsEmpty == true {
            imagePicker = UIImagePickerController()
            imagePicker?.delegate      = self
            imagePicker?.allowsEditing = false
            imagePicker?.videoMaximumDuration = MAX_VIDEO_DURATION
            
            if UIImagePickerController.isSourceTypeAvailable( UIImagePickerControllerSourceType.Camera ){
                imagePicker?.sourceType = .Camera
            } else {
                imagePicker?.sourceType = .PhotoLibrary
            }
            //imagePicker?.mediaTypes = [ kUTTypeImage as String ]
            imagePicker?.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType((imagePicker?.sourceType)!)!
            
            showCamera(false)
        }
    }
    
    func showCamera(animated:Bool){
        Async.main(after: 0.1) { () -> Void in
            self.presentViewController(self.imagePicker!, animated: animated, completion: nil)
        }
    }
    
    //Hide the modal camera window
    func hideCamera(animated:Bool){
        imagePicker?.dismissViewControllerAnimated(animated, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        //Dismiss a view controller that was presented modally
        picker.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        //1. Handle images
        //2. Handle videos
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        //Camera took a photo
        if( mediaType == kUTTypeImage as String ){
            //Only store this image if the camera was used
            self.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            //Save the image
            if imagePicker?.sourceType == .Camera{
                UIImageWriteToSavedPhotosAlbum(self.image!, nil, nil, nil)
            }
        }
        //Camera took a video
        else {
            videoFilePath = info[UIImagePickerControllerMediaURL]!.path
            print(videoFilePath)
            //Save the video
            if imagePicker?.sourceType == .Camera{
                //Check to see that we can actually save a video
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoFilePath!) {
                    UISaveVideoAtPathToSavedPhotosAlbum(videoFilePath!, nil, nil, nil)
                }
            }
        }
        hideCamera(true)
    }
}

